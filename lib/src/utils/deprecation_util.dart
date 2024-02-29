import 'dart:convert';
import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

import '../models/config_model.dart';
import '../services/config_repository.dart';
import '../services/logger_service.dart';
import 'constants.dart';
import 'context.dart';

void deprecationWorkflow() {
  _warnDeprecatedEnvVars();
  final fvmDir = ctx.fvmDir;
  final legacySettingsFile = File(join(fvmDir, '.settings'));

  if (!legacySettingsFile.existsSync()) {
    return;
  }

  final payload = legacySettingsFile.readAsStringSync();
  try {
    final settings = jsonDecode(payload);
    final settingsCachePath = settings['cachePath'] as String?;
    if (settingsCachePath != null && settingsCachePath != fvmDir) {
      var appConfig = ConfigRepository.loadAppConfig();
      appConfig = appConfig.copyWith(cachePath: fvmDir);
      ConfigRepository.save(appConfig);
      legacySettingsFile.deleteSync(recursive: true);
      logger.success(
        'We have moved the settings file ${legacySettingsFile.path}'
        'Your settings have been migrated to $kAppConfigFile'
        'Your cachePath is now $settingsCachePath. FVM will exit now. Please run the command again.',
      );
      // Exit to prevent execution with wrong cache path
      exit(ExitCode.success.code);
    }
  } catch (_) {
    logger.warn('Could not parse legacy settings file');
    legacySettingsFile.deleteSync(recursive: true);
  }
}

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
}
