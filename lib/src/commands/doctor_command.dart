import 'package:io/io.dart';
import 'package:process_run/shell.dart';

import '../../constants.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../utils/logger.dart';
import 'base_command.dart';

/// Information about fvm environment
class DoctorCommand extends BaseCommand {
  @override
  final name = 'doctor';

  @override
  final description = 'Output info about fvm, and the environment '
      'configuration in a specific project';

  /// Constructor
  DoctorCommand();

  @override
  Future<int> run() async {
    final project = await ProjectService.findAncestor();

    // Flutter exec path
    final flutterWhich = await which('flutter');

    // dart exec path
    final dartWhich = await which('dart');

    if (project.pinnedVersion != null) {
      final cacheVersion =
          await CacheService.getByVersionName(project.pinnedVersion!);
      FvmLogger.spacer();
      FvmLogger.fine('FVM config found:');
      FvmLogger.divider();
      FvmLogger.info('Project: ${project.name}');
      FvmLogger.info('Directory: ${project.projectDir.path}');
      FvmLogger.info('Version: ${project.pinnedVersion}');
      FvmLogger.info(
        'Project Environment: ${(project.config.activeEnv) ?? "None selected"}',
      );
      FvmLogger.divider();
      if (cacheVersion == null) {
        FvmLogger.warning(
          'Version is not currently cached. Run "fvm install" on this'
          ' directory, or "fvm install ${project.pinnedVersion}" anywhere.',
        );
      } else {
        FvmLogger.fine('Version is currently cached locally.');
        FvmLogger.spacer();
        FvmLogger.info('Cache Path: ${cacheVersion.dir.path}');
        FvmLogger.info('Channel: ${cacheVersion.isChannel}');

        final sdkVersion = CacheService.getSdkVersionSync(cacheVersion);
        if (sdkVersion != null) {
          FvmLogger.info('SDK Version: $sdkVersion');
        } else {
          FvmLogger.warning(
            'SDK Version: Need to finish setup. Run "fvm flutter doctor"',
          );
        }
      }
      FvmLogger.spacer();
      FvmLogger.info('IDE Links');
      FvmLogger.info('VSCode: .fvm/flutter_sdk');
      FvmLogger.info('Android Studio: ${project.config.sdkSymlink.path}');
      FvmLogger.spacer();
    } else {
      FvmLogger.spacer();
      FvmLogger.fine('No FVM config found:');
      FvmLogger.info(kWorkingDirectory.path);
      FvmLogger.info(
        'Fvm will run the version in your PATH env: $flutterWhich',
      );
    }
    FvmLogger.spacer();
    FvmLogger.fine('Configured env paths:');
    FvmLogger.divider();
    FvmLogger.info('Flutter:');
    FvmLogger.info(flutterWhich ?? '');
    FvmLogger.spacer();
    FvmLogger.info('Dart:');
    FvmLogger.info(dartWhich ?? '');
    FvmLogger.spacer();

    return ExitCode.success.code;
  }
}
