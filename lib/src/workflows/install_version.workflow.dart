import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/git_tools.dart';

import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:io/io.dart';

import '../utils/logger.dart';

Future<void> installWorkflow(
  String version, {
  bool skipConfirmation = false,
}) async {
  try {
    assert(version != null);

    // If it's installed correctly just return and use cached
    final cacheVersion = await CacheService.isVersionCached(version);

    if (cacheVersion != null) {
      logger.trace('Version: $version - already installed.');
      return;
    }

    // Ensure the config link and symlink are updated
    final project = await FlutterAppService.findAncestor();
    await FlutterAppService.updateSdkLink(project);

    FvmLogger.info('Flutter $version is not installed.');

    // Install if input is confirmed, allows ot skip confirmation for testing purpose
    if (skipConfirmation || await confirm('Would you like to install it?')) {
      FvmLogger.fine('Installing version: $version');
      await runGitClone(version);
      FvmLogger.fine('Version installed: $version');
    } else {
      // Exit if don't want to install
      exit(ExitCode.success.code);
    }
  } on Exception catch (err) {
    logger.trace(err.toString());
    throw InternalError('Could not install <$version>');
  }
}
