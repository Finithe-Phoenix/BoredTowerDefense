#!/bin/sh

# Run specific tests to see detailed output
echo "Installing dependencies..."
flutter pub get

echo ""
echo "Running specific failing tests..."
echo ""

# Run only specific test files and show detailed output
flutter test test/world_art_generator_test.dart --reporter expanded 2>&1

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

flutter test test/world_chronicles_test.dart --reporter expanded 2>&1
