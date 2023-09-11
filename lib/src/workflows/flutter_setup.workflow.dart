import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/logger.dart';

Future<void> setupFlutterWorkflow({
  required CacheFlutterVersion version,
}) async {
  // Skip if its test
  if (!version.notSetup || ctx.isTest) return;

  logger
    ..info('Setting up Flutter SDK: ${version.name}')
    ..spacer;

  await FlutterTools.instance.runSetup(version);
}

Future<void> resolveDependenciesWorkflow({
  required CacheFlutterVersion version,
  required Project project,
}) async {
  final dartGeneratorVersion = project.dartToolGeneratorVersion;
  final dartToolVersion = project.dartToolVersion;

  logger
    ..detail('')
    ..detail('Dart generator version: $dartGeneratorVersion')
    ..detail('Dart SDK version: ${version.dartSdkVersion}')
    ..detail('')
    ..detail('Dart tool version: $dartToolVersion')
    ..detail('SDK Version: ${version.flutterSdkVersion}')
    ..detail('');

  if (dartToolVersion == version.flutterSdkVersion) {
    logger.detail('Dart tool version matches SDK version, skipping resolve.');
    return;
  }

  logger
    ..detail('')
    ..detail('SDK version mismatch.\n')
    ..detail('Dart tool version: $dartToolVersion')
    ..detail('Flutter SDK Version: ${version.flutterSdkVersion}')
    ..detail('');

  final isVscode = Platform.environment['TERM_PROGRAM'] == 'vscode';

  // Skip resolve if in vscode
  if (isVscode) {
    logger.notice(
      'You are running on VSCode, please close your \nterminal and open again to see the changes. \n to just use "flutter" command.',
    );
  }

  final progress = logger.progress('Resolving dependencies...');

  try {
    await FlutterTools.instance.runPubGet(version);

    progress.complete('Dependencies resolved.');
  } on Exception {
    if (project.dartToolVersion == version.flutterSdkVersion) {
      progress.complete('Dependencies resolved.');
    } else {
      progress.fail('Could not resolve dependencies.');
      rethrow;
    }
  }
}
