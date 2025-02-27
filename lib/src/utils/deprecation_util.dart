import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import '../models/config_model.dart';
import 'context.dart';

void deprecationWorkflow() {
  _warnDeprecatedEnvVars();
}

// TODO: Removed on future version of the app
// Deprecated on 3.0.0
void _warnDeprecatedEnvVars() {
  const oldFlutterUrlEnv = 'FVM_GIT_CACHE';
  const oldCachePathEnv = 'FVM_HOME';
  final flutterRoot = Platform.environment[oldFlutterUrlEnv];
  final fvmHome = Platform.environment[oldCachePathEnv];
  if (flutterRoot != null) {
    ctx.loggerService
        .err('$oldFlutterUrlEnv environment variable is deprecated. ');
    ctx.loggerService.info('Please use ${ConfigKeys.flutterUrl.envKey}');
    final confirmation = ctx.loggerService.confirm(
      'Do you want to proceed? This might impact the expected behavior.',
      defaultValue: false,
    );
    if (!confirmation) {
      exit(ExitCode.success.code);
    }

    return;
  }

  if (fvmHome != null) {
    ctx.loggerService
        .warn('$oldCachePathEnv environment variable is deprecated. ');
    ctx.loggerService.info('Please use ${ConfigKeys.cachePath.envKey} instead');
  }
}
