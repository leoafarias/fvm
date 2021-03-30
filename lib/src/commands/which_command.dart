import 'package:args/command_runner.dart';
import 'package:fvm/fvm.dart';

import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_tools.dart';

import 'package:fvm/src/utils/logger.dart';

import 'package:io/io.dart';
import 'package:process_run/shell.dart';

/// Returns which version of Flutter will run
class WhichCommand extends Command<int> {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'which';

  @override
  final description = 'Which version of Flutter will run';

  /// Constructor
  WhichCommand();

  @override
  Future<int> run() async {
    final project = await FlutterAppService.findAncestor();

    if (project != null && project.pinnedVersion != null) {
      final cacheVersion =
          await CacheService.getByVersionName(project.pinnedVersion);
      FvmLogger.spacer();
      FvmLogger.fine('FVM config found:');
      FvmLogger.divider();
      FvmLogger.info('Project: ${project.name}');
      FvmLogger.info('Directory: ${project.projectDir.path}');
      FvmLogger.info('Version: ${project.pinnedVersion}');
      FvmLogger.info(
          'Project Environment: ${(project.config.activeEnv) ?? "Not configured"}');
      FvmLogger.divider();
      if (cacheVersion == null) {
        FvmLogger.warning(
          'Version is not currently cached. Run "fvm install" on this directory, or "fvm install ${project.pinnedVersion}" anywhere.',
        );
      } else {
        FvmLogger.fine('Version is currently cached locally.');
        FvmLogger.info('Cache Path: ${cacheVersion.dir.path}');
        FvmLogger.info('Channel: ${cacheVersion.isChannel}');

        final sdkVersion = await FlutterTools.getSdkVersion(cacheVersion);
        if (sdkVersion != null) {
          FvmLogger.info('SDK Version: $sdkVersion');
        } else {
          FvmLogger.info(
              'SDK Version: Need to finish setup. Run "fvm flutter doctor"');
        }
      }
    } else {
      final execPath = await which('flutter');
      FvmLogger.spacer();
      FvmLogger.fine('No FVM config found:');
      FvmLogger.info('Fvm will run the version in your PATH env: $execPath');
    }
    FvmLogger.spacer();

    return ExitCode.success.code;
  }
}
