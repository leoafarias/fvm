import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/utils/pubdev.dart';
import 'package:fvm/src/version.dart';
import 'package:path/path.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';
import 'package:test/test.dart';

void main() {
  test('Is Valid Flutter Version', () async {
    expect(await inferFlutterVersion('1.8.1'), 'v1.8.1');
    expect(await inferFlutterVersion('v1.8.1'), 'v1.8.1');

    expect(await inferFlutterVersion('1.9.6'), 'v1.9.6');
    expect(await inferFlutterVersion('v1.9.6'), 'v1.9.6');

    expect(await inferFlutterVersion('1.10.5'), 'v1.10.5');
    expect(await inferFlutterVersion('v1.10.5'), 'v1.10.5');

    expect(await inferFlutterVersion('1.9.1+hotfix.4'), 'v1.9.1+hotfix.4');
    expect(await inferFlutterVersion('v1.9.1+hotfix.4'), 'v1.9.1+hotfix.4');

    expect(await inferFlutterVersion('1.17.0-dev.3.1'), '1.17.0-dev.3.1');
  });

  test('Not Valid Flutter Version', () async {
    expect(inferFlutterVersion('1.8.0.2'), throwsA(anything));
    expect(inferFlutterVersion('v1.17.0-dev.3.1'), throwsA(anything));
  });

  test('Check if FVM latest version', () async {
    var isLatest = await checkIfLatestVersion(currentVersion: '1.0.0');
    expect(isLatest, false);

    isLatest = await checkIfLatestVersion(currentVersion: '5.0.0');
    expect(isLatest, true);
  });

  test('Does CLI version match', () async {
    final pubspec = File(
      join(kWorkingDirectory.path, 'pubspec.yaml'),
    ).readAsStringSync().toPubspecYaml();
    expect(pubspec.version.valueOr(() => null), packageVersion);
  });

  test('Test ReplaceFlutterPathEnv', () async {
    final version = 'stable';
    final envName = 'PATH';
    final emptyEnvVar = replaceFlutterPathEnv('');
    final nullEnvVar = replaceFlutterPathEnv(null);

    final newEnvVar = replaceFlutterPathEnv(version);
    final flutterPath = join(kVersionsDir.path, version, 'bin');

    expect(emptyEnvVar[envName], envVars[envName]);
    expect(nullEnvVar[envName], envVars[envName]);
    expect(newEnvVar[envName].contains(flutterPath), true);
  });
}
