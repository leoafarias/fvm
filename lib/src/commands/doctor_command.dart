import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/context.dart';
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
      final cacheVersion = CacheService.getVersion(
        FlutterVersion(project.pinnedVersion!),
      );
      logger
        ..info('')
        ..info('FVM Version: $packageVersion')
        ..info('')
        ..info('FVM Config found:')
        ..info('')
        ..info('Project: ${project.name}')
        ..info('Directory: ${project.projectDir.path}')
        ..info('Version: ${project.pinnedVersion}')
        ..info(
          'Project Flavor: ${(project.activeFlavor) ?? "None selected"}',
        );

      if (cacheVersion == null) {
        logger.warn(
          'Version is not currently cached. Run "fvm install" on this'
          ' directory, or "fvm install ${project.pinnedVersion}" anywhere.',
        );
      } else {
        logger
          ..success('Version is currently cached locally.')
          ..info('')
          ..info('Cache Path: ${cacheVersion.directory}')
          ..info('Channel: ${cacheVersion.isChannel}');

        if (cacheVersion.sdkVersion != null) {
          logger.info('SDK Version: ${cacheVersion.sdkVersion}');
        } else {
          logger.warn(
            'SDK Version: Need to finish setup. Run "fvm flutter doctor"',
          );
        }
      }
      logger
        ..info('')
        ..info('IDE Links')
        ..info('VSCode: .fvm/flutter_sdk')
        ..info('Android Studio: ${project.cacheVersionSymlink.path}')
        ..info('');
    } else {
      logger
        ..info('')
        ..info('No FVM config found:')
        ..info(kWorkingDirectory.path)
        ..info('FVM will run the version in your PATH env: $flutterWhich');
    }
    logger
      ..spacer
      ..success('Configured env paths:')
      ..divider
      ..info('Flutter:')
      ..info(flutterWhich ?? '')
      ..spacer
      ..info('Dart:')
      ..info(dartWhich ?? '')
      ..spacer
      ..info('FVM_HOME:')
      ..info(ctx.environment['FVM_HOME'] ?? 'not set')
      ..spacer
      ..info('''
''');

    return ExitCode.success.code;
  }
}
