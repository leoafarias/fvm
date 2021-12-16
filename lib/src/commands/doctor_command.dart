import 'package:io/io.dart';
import 'package:process_run/shell.dart';

import '../../constants.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../utils/logger.dart';
import '../version.dart';
import 'base_command.dart';

/// Information about fvm environment
class DoctorCommand extends BaseCommand {
  @override
  final name = 'doctor';

  @override
  final description = 'Shows information about environment, '
      'and project configuration.';

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
      Logger.spacer();

      Logger.info('FVM Version: $packageVersion');
      Logger.divider();
      Logger.fine('FVM config found:');
      Logger.divider();
      Logger.info('Project: ${project.name}');
      Logger.info('Directory: ${project.projectDir.path}');
      Logger.info('Version: ${project.pinnedVersion}');
      Logger.info(
        'Project Flavor: ${(project.config.activeFlavor) ?? "None selected"}',
      );
      Logger.divider();
      if (cacheVersion == null) {
        Logger.warning(
          'Version is not currently cached. Run "fvm install" on this'
          ' directory, or "fvm install ${project.pinnedVersion}" anywhere.',
        );
      } else {
        Logger.fine('Version is currently cached locally.');
        Logger.spacer();
        Logger.info('Cache Path: ${cacheVersion.dir.path}');
        Logger.info('Channel: ${cacheVersion.isChannel}');

        final sdkVersion = CacheService.getSdkVersionSync(cacheVersion);
        if (sdkVersion != null) {
          Logger.info('SDK Version: $sdkVersion');
        } else {
          Logger.warning(
            'SDK Version: Need to finish setup. Run "fvm flutter doctor"',
          );
        }
      }
      Logger.spacer();
      Logger.info('IDE Links');
      Logger.info('VSCode: .fvm/flutter_sdk');
      Logger.info('Android Studio: ${project.config.sdkSymlink.path}');
      Logger.spacer();
    } else {
      Logger.spacer();
      Logger.fine('No FVM config found:');
      Logger.info(kWorkingDirectory.path);
      Logger.info(
        'Fvm will run the version in your PATH env: $flutterWhich',
      );
    }
    Logger.spacer();
    Logger.fine('Configured env paths:');
    Logger.divider();
    Logger.info('Flutter:');
    Logger.info(flutterWhich ?? '');
    Logger.spacer();
    Logger.info('Dart:');
    Logger.info(dartWhich ?? '');
    Logger.spacer();
    Logger.info('FVM_HOME:');
    Logger.info(kEnvVars['FVM_HOME'] ?? 'not set');
    Logger.spacer();

    return ExitCode.success.code;
  }
}
