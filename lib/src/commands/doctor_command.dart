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
      final cacheVersion = await CacheService.getByVersionName(
        project.pinnedVersion!,
      );
      logger.info('');

      logger.info('FVM Version: $packageVersion');
      logger.divider();
      logger.fine('FVM config found:');
      logger.divider();
      logger.info('Project: ${project.name}');
      logger.info('Directory: ${project.projectDir.path}');
      logger.info('Version: ${project.pinnedVersion}');
      logger.info(
        'Project Flavor: ${(project.config.activeFlavor) ?? "None selected"}',
      );
      logger.divider();
      if (cacheVersion == null) {
        logger.warning(
          'Version is not currently cached. Run "fvm install" on this'
          ' directory, or "fvm install ${project.pinnedVersion}" anywhere.',
        );
      } else {
        logger.fine('Version is currently cached locally.');
        logger.spacer();
        logger
          ..info('Cache Path: ${cacheVersion.dir.path}')
          ..info('Channel: ${cacheVersion.isChannel}');

        if (cacheVersion.sdkVersion != null) {
          logger.info('SDK Version: ${cacheVersion.sdkVersion}');
        } else {
          logger.warning(
            'SDK Version: Need to finish setup. Run "fvm flutter doctor"',
          );
        }
      }
      logger
        ..info('')
        ..info('IDE Links')
        ..info('VSCode: .fvm/flutter_sdk')
        ..info('Android Studio: ${project.config.sdkSymlink.path}')
        ..info('');
    } else {
      logger
        ..info('')
        ..info('No FVM config found:')
        ..info(kWorkingDirectory.path)
        ..info('FVM will run the version in your PATH env: $flutterWhich');
    }
    logger.info('');
    logger.fine('Configured env paths:');
    logger.divider();
    logger.info('Flutter:');
    logger.info(flutterWhich ?? '');
    logger.info('');
    logger.info('Dart:');
    logger.info(dartWhich ?? '');
    logger.info('');
    logger.info('FVM_HOME:');
    logger.info(kEnvVars['FVM_HOME'] ?? 'not set');
    logger.info('');

    logger.info('''
''');

    return ExitCode.success.code;
  }
}
