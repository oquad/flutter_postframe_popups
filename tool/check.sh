#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze --no-pub --fatal-infos --fatal-warnings
dart run dart_code_linter:metrics analyze lib example/lib test example/test \
  --fatal-warnings --fatal-style --fatal-performance \
  --set-exit-on-violation-level=warning
flutter test --no-pub
flutter test --platform chrome --no-pub test/spotlight_test.dart \
  test/measure_test.dart test/memory_pressure_test.dart \
  test/pointer_listener_test.dart test/app_lifecycle_test.dart \
  test/visibility_trigger_test.dart
(cd example && flutter test --no-pub)
flutter pub publish --dry-run
