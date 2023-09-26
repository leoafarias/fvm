import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:path/path.dart';

void deprecationWorkflow(
  String fvmDir,
) {
  _warnDeprecatedEnvVars();

  final settingsFile = File(join(fvmDir, '.settings'));

  if (!settingsFile.existsSync()) {
    return;
  }

  final payload = settingsFile.readAsStringSync();
  try {
    final settings = jsonDecode(payload);

    if (settings['cachePath'] != join(fvmDir, 'versions')) {
      logger.confirm(
        'You have a deprecated setting for cachePath in $settingsFile.'
        'Make sure you update it. $kFvmDocsConfigUrl',
      );
    }
  } catch (_) {
    logger.warn('Could not parse legact settings file');
  }

  settingsFile.deleteSync(recursive: true);
}

Future<void> _migrateVersionSyntax() async {
  final versions = await CacheService.fromContext.getAllVersions();

  final oldVersions = versions.where((version) {
    final versionName = version.name;
    final versionParts = versionName.split('@');
    if (versionParts.length > 1) {
      return true;
    }
    return false;
  });

  if (oldVersions.isEmpty) {
    return;
  }

  logger.warn('You have a deprecated version / channel syntax. ');

  for (var element in oldVersions) {
    logger
      ..info(element.name)
      ..spacer
      ..info('Run: fvm remove ${element.name}}')
      ..spacer
      ..info('Then run: fvm install ${element.name.split('@').first}')
      ..info(
        'if you need to force install a channel run: fvm install ${element.name.split('@').first} --channel beta',
      );
  }
}

// TODO: Removed on future version of the app
// Deprecated on 3.0.0
void _warnDeprecatedEnvVars() {
  final flutterRoot = Platform.environment['FVM_GIT_CACHE'];
  final fvmHome = Platform.environment['FVM_HOME'];
  if (flutterRoot != null) {
    logger.warn('FVM_GIT_CACHE environment variable is deprecated. ');
    logger.info('Please use ${ConfigVariable.gitCachePath.envName}');
  }

  if (fvmHome != null) {
    logger.warn('FVM_HOME environment variable is deprecated. ');
    logger.info('Please use ${ConfigVariable.fvmPath.envName} instead');
  }

  if (flutterRoot == null || fvmHome == null) {
    return;
  }
}
