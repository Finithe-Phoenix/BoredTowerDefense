#!/bin/sh

# Run Flutter tests with coverage and show summary
echo "Installing dependencies..."
flutter pub get

echo ""
echo "Running tests (this may take a while)..."
echo ""

# Run tests and capture output to file (suppress normal output)
flutter test --coverage > /tmp/test_output.txt 2>&1
EXIT_CODE=$?

# Get the last line that contains test results
RESULT_LINE=$(tail -5 /tmp/test_output.txt | grep -E '[0-9]+:[0-9]+ \+[0-9]+' | tail -1)

# Extract numbers using sed
PASSED=$(echo "$RESULT_LINE" | sed -n 's/.*+\([0-9]*\).*/\1/p')
FAILED=$(echo "$RESULT_LINE" | sed -n 's/.*-\([0-9]*\).*/\1/p')

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

if [ "$FAILED" = "0" ] || [ -z "$FAILED" ]; then
    echo "  ✅ ALL TESTS PASSED!"
else
    echo "  ❌ SOME TESTS FAILED ($FAILED failures)"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                     FAILED TESTS                               "
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    # Show compilation errors
    grep -E "Error:.*isn't defined|Compilation failed" /tmp/test_output.txt | head -20
    echo ""
    # Show failed test files (unique)
    grep -E "Some tests failed|FAILED" /tmp/test_output.txt | head -10
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
