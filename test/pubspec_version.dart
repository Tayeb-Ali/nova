import 'dart:io';

// Version declared in pubspec.yaml (`version: <version>+<buildNumber>`),
// the single source of truth. Tests pin their package_info_plus mocks to
// these instead of hardcoded literals, so a version bump never rots the
// suite. `flutter test` runs with the package root as CWD, which is where
// this resolves from.
({String version, String buildNumber}) _read() {
  final text = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*([^\s+#]+)\+([^\s#]+)',
    multiLine: true,
  ).firstMatch(text);
  assert(match != null, 'pubspec.yaml must declare version: <v>+<build>');
  return (version: match!.group(1)!, buildNumber: match.group(2)!);
}

({String version, String buildNumber})? _cached;

/// App version from pubspec.yaml (e.g. `0.1.6`).
String get pubspecVersion => (_cached ??= _read()).version;

/// Build number from pubspec.yaml (e.g. `6`).
String get pubspecBuildNumber => (_cached ??= _read()).buildNumber;
