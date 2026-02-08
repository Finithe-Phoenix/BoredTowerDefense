#!/bin/sh

# Run Flutter tests with coverage and show summary
echo "Installing dependencies..."
flutter pub get

echo ""
echo "Running tests (this may take a while)..."
echo ""

# Optional: run a subset of tests to avoid OOM.
# Usage: set env var TEST_TARGETS, e.g. "test/aurora_effect_simulation_test.dart".
TEST_TARGETS="${TEST_TARGETS:-$*}"

# Run tests and capture output to file
# Notes:
# - `-r expanded` helps us see which test(s) failed.
# - `-j 1` reduces flakiness / resource spikes in CI-like containers.
# - If TEST_TARGETS is non-empty, we only run those tests (batch mode).
if [ -n "$TEST_TARGETS" ]; then
  echo "Running targeted tests: $TEST_TARGETS"
  flutter test -r expanded -j 1 --coverage $TEST_TARGETS > /tmp/test_output.txt 2>&1
else
  flutter test -r expanded -j 1 --coverage > /tmp/test_output.txt 2>&1
fi
EXIT_CODE=$?

# Try to find a summary line (formats vary).
RESULT_LINE=$(grep -E '^[0-9]+:[0-9]+ \+[0-9]+.*$' /tmp/test_output.txt | tail -1)

# Extract numbers using sed (best-effort)
PASSED=$(echo "$RESULT_LINE" | sed -n 's/.*+\([0-9][0-9]*\).*/\1/p')
FAILED=$(echo "$RESULT_LINE" | sed -n 's/.*-\([0-9][0-9]*\).*/\1/p')

# Default values
if [ -z "$PASSED" ]; then PASSED=0; fi
if [ -z "$FAILED" ]; then FAILED=0; fi

# Show summary
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                       TEST SUMMARY                              "
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "  ✓ Passed:      $PASSED"
echo "  ✗ Failed:      $FAILED"
echo ""

if [ "$EXIT_CODE" -eq 0 ]; then
    echo "  ✅ ALL TESTS PASSED!"
else
    # Even if we couldn't parse FAILED count, a non-zero exit means something went wrong.
    echo "  ❌ TEST COMMAND EXITED WITH CODE $EXIT_CODE"
    if [ -n "$FAILED" ] && [ "$FAILED" != "0" ]; then
      echo "  (Detected $FAILED failures in summary parsing)"
    fi
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                     FAILED TESTS                               "
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Most relevant failure lines (first 160):"
    # Flutter test output is noisy; pull the high-signal lines.
    grep -nE "^(FAIL|ERROR|EXCEPTION|Expected:|Actual:|Which:|Stack trace:|package:|test/|lib/|Some tests failed|Compilation failed|Error:|Fatal:)" /tmp/test_output.txt | head -160

    echo ""
    echo "Last ~200 lines of raw output:"
    tail -200 /tmp/test_output.txt
fi

echo ""
echo "════════════════════════════════════════════════════════════════"

# Coverage info
if [ -f coverage/lcov.info ]; then
    echo "  📊 Coverage report: coverage/lcov.info"
    echo "════════════════════════════════════════════════════════════════"
fi

echo ""
exit $EXIT_CODE
