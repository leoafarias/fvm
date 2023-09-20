import 'dart:io';

import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/version.g.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('Does CLI version match', () async {
    final yaml = File(
      join(Directory.current.path, 'pubspec.yaml'),
    ).readAsStringSync();
    final pubspec = loadYamlNode(yaml);
    expect(pubspec.value['version'], packageVersion);
  });

  test('Test update env variables', () async {
    final envVars = Platform.environment;
    // final version = 'stable';
    final envName = 'PATH';
    final fakePath = 'FAKE_PATH';

    final newEnvVar =
        updateEnvironmentVariables(['FAKE_PATH', 'ANOTHER_FAKE_PATH'], envVars);

    // expect(newEnvVar[envName], envVars[envName]);
    expect(newEnvVar[envName]!.contains(fakePath), true);
    expect(newEnvVar[envName]!.contains('ANOTHER_FAKE_PATH'), true);
    expect(envVars, isNot(newEnvVar));
  });

  test('Assigns version weights', () async {
    expect('500.0.0', assignVersionWeight('2da03e5'));
    expect('500.0.0', assignVersionWeight('ce18d702e9'));
    expect(
      '500.0.0',
      assignVersionWeight('ce18d702e90d3dff9fee53d61a770c94f14f2811'),
    );
    expect('400.0.0', assignVersionWeight('master'));
    expect('300.0.0', assignVersionWeight('stable'));
    expect('200.0.0', assignVersionWeight('beta'));
    expect('100.0.0', assignVersionWeight('dev'));
  });

  group('extractFlutterVersionOutput', () {
    test('should correctly parse the EXAMPLE:1', () {
      final content =
          '''Flutter 3.15.0-15.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision b2ec15bfa3 (5 days ago) • 2023-09-14 15:31:44 -0500
Engine • revision 5c86194494
Tools • Dart 3.2.0 (build 3.2.0-134.1.beta) • DevTools 2.27.0''';

      final result = extractFlutterVersionOutput(content);

      expect(result.flutterVersion, '3.15.0-15.1.pre');
      expect(result.channel, 'beta');
      expect(result.dartVersion, '3.2.0');
      expect(result.dartBuildVersion, '3.2.0-134.1.beta');
    });

    test('should correctly parse the EXAMPLE:2', () {
      final content =
          '''Flutter 3.10.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 796c8ef792 (3 months ago) • 2023-06-13 15:51:02 -0700
Engine • revision 45f6e00911
Tools • Dart 3.0.5 • DevTools 2.23.1''';

      final result = extractFlutterVersionOutput(content);

      expect(result.flutterVersion, '3.10.5');
      expect(result.channel, 'stable');
      expect(result.dartVersion, '3.0.5');
      expect(result.dartBuildVersion, '3.0.5');
    });

    test('should correctly parse the EXAMPLE:3', () {
      final content =
          '''Flutter 2.2.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision b22742018b (2 years, 4 months ago) • 2021-05-14 19:12:57 -0700
Engine • revision a9d88a4d18
Tools • Dart 2.13.0''';

      final result = extractFlutterVersionOutput(content);

      expect(result.flutterVersion, '2.2.0');
      expect(result.channel, 'stable');
      expect(result.dartVersion, '2.13.0');
      expect(result.dartBuildVersion, '2.13.0');
    });
  });
}
