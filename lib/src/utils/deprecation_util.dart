import 'dart:io';

import 'package:mason_logger/mason_logger.dart' as mason;

import '../models/config_model.dart';
import '../services/logger_service.dart';

// TODO: Removed on future version of the app
// Deprecated on 3.0.0
void deprecationWorkflow(Logger loggerService) {
  const oldFlutterUrlEnv = 'FVM_GIT_CACHE';
  const oldCachePathEnv = 'FVM_HOME';
  final flutterRoot = Platform.environment[oldFlutterUrlEnv];
  final fvmHome = Platform.environment[oldCachePathEnv];
  if (flutterRoot != null) {
    loggerService.err('$oldFlutterUrlEnv environment variable is deprecated. ');
    loggerService.info('Please use ${ConfigKeys.flutterUrl.envKey}');
    final confirmation = loggerService.confirm(
      'Do you want to proceed? This might impact the expected behavior.',
      defaultValue: false,
    );
    if (!confirmation) {
      exit(mason.ExitCode.success.code);
    }

    return;
  }

  if (fvmHome != null) {
    loggerService.warn('$oldCachePathEnv environment variable is deprecated. ');
    loggerService.info('Please use ${ConfigKeys.cachePath.envKey} instead');
  }
}
