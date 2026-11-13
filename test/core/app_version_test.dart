import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/app_version.dart';

void main() {
  test('app_version.dart matches the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true)
        .firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml has no version line');

    expect(
      '$appVersion+$appBuild',
      match!.group(1),
      reason: 'Update lib/core/app_version.dart when bumping pubspec.yaml',
    );
  });

  test('appVersionLabel is v-prefixed appVersion', () {
    expect(appVersionLabel, 'v$appVersion');
  });
}
