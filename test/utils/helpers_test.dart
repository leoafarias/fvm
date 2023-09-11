import 'dart:io';

import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/version.g.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('Does CLI version match', () async {
    final yaml = File(
      join(ctx.workingDirectory, 'pubspec.yaml'),
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
}
