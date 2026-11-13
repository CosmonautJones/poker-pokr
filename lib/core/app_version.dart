/// The app version shown in the UI.
///
/// Keep these in step with `version:` in `pubspec.yaml`
/// (`<appVersion>+<appBuild>`). `test/core/app_version_test.dart` fails if
/// they drift apart.
const appVersion = '0.1.1';

/// Build number: the part after `+` in the pubspec version.
const appBuild = 3;

/// Short label for compact spots, e.g. `v0.1.1`.
const appVersionLabel = 'v$appVersion';
