import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

void deprecationWorkflow() {
  _warnDeprecatedEnvVars();
  final fvmDir = ctx.fvmDir;
  final settingsFile = File(join(fvmDir, '.settings'));

  if (!settingsFile.existsSync()) {
    return;
  }

  final payload = settingsFile.readAsStringSync();
  try {
    final settings = jsonDecode(payload);
    final settingsCachePath = settings['cachePath'] as String?;
    if (settingsCachePath != null && settingsCachePath != fvmDir) {
      var appConfig = ConfigRepository.loadFile();
      appConfig = appConfig.copyWith(cachePath: fvmDir);
      ConfigRepository.save(appConfig);
      settingsFile.deleteSync(recursive: true);
      logger.success(
        'We have moved the settings file ${settingsFile.path}'
        'Your settings have been migrated to $kAppConfigFile'
        'Your cachePath is now $settingsCachePath. FVM will exit now. Please run the command again.',
      );
      // Exit to prevent execution with wrong cache path
      exit(ExitCode.success.code);
    }
  } catch (_) {
    logger.warn('Could not parse legact settings file');
  }
}

// Future<void> _migrateVersionSyntax() async {
//   final versions = await CacheService.fromContext.getAllVersions();

//   final oldVersions = versions.where((version) {
//     final versionName = version.name;
//     final versionParts = versionName.split('@');
//     if (versionParts.length > 1) {
//       return true;
//     }
//     return false;
//   });

//   if (oldVersions.isEmpty) {
//     return;
//   }

//   logger.warn('You have a deprecated version / channel syntax. ');

//   for (var element in oldVersions) {
//     logger
//       ..info(element.name)
//       ..spacer
//       ..info('Run: fvm remove ${element.name}}')
//       ..spacer
//       ..info('Then run: fvm install ${element.name.split('@').first}')
//       ..info(
//         'if you need to force install a channel run: fvm install ${element.name.split('@').first} --channel beta',
//       );
//   }
// }

// TODO: Removed on future version of the app
// Deprecated on 3.0.0
void _warnDeprecatedEnvVars() {
  const oldFlutterUrlEnv = 'FVM_GIT_CACHE';
  const oldCachePathEnv = 'FVM_HOME';
  final flutterRoot = Platform.environment[oldFlutterUrlEnv];
  final fvmHome = Platform.environment[oldCachePathEnv];
  if (flutterRoot != null) {
    logger.err('$oldFlutterUrlEnv environment variable is deprecated. ');
    logger.info('Please use ${ConfigKeys.flutterUrl.envKey}');
    final confirmation = logger.confirm(
      'Do you want to proceed? This might impact the expected behavior.',
    );
    if (!confirmation) {
      exit(ExitCode.success.code);
    }
    return;
  }

  if (fvmHome != null) {
    logger.warn('$oldCachePathEnv environment variable is deprecated. ');
    logger.info('Please use ${ConfigKeys.cachePath.envKey} instead');
  }

  if (flutterRoot == null || fvmHome == null) {}
}
