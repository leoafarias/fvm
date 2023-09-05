import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/services/flutter_tools.dart';
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
  final dartToolVersion = project.dartToolVersion;

  logger
    ..detail('')
    ..detail('dartToolVersion: $dartToolVersion')
    ..detail('cacheVersion.sdkVersion: ${version.sdkVersion}')
    ..detail('');

  if (dartToolVersion != version.sdkVersion) {
    logger
      ..detail('')
      ..detail('dart_tool version mismatch.\n')
      ..detail('Dart tool version: $dartToolVersion')
      ..detail('SDK Version: ${version.sdkVersion}')
      ..detail('');

    final isVscode = Platform.environment['TERM_PROGRAM'] == 'vscode';

    // Skip resolve if in vscode
    if (isVscode) {
      logger.detail('Skipping resolve in vscode.');
      return;
    }

    final progress = logger.progress('Resolving dependencies...');

    try {
      await FlutterTools.instance.runPubGet(version);

      progress.complete('Dependencies resolved.');
    } on Exception {
      if (project.dartToolVersion == version.sdkVersion) {
        progress.complete('Dependencies resolved.');
      } else {
        progress.fail('Could not resolve dependencies.');
        rethrow;
      }
    }
  }
}
