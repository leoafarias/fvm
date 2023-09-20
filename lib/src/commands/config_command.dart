import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../utils/context.dart';
import 'base_command.dart';

/// Fvm Config
class ConfigCommand extends BaseCommand {
  @override
  final name = 'config';

  @override
  final description = 'Set configuration for FVM';

  /// Constructor
  ConfigCommand() {
    argParser
      ..addOption(
        ConfigVariable.flutterRepo.argName,
        help: 'ADVANCED: Set Flutter repo url to clone from.',
      )
      ..addFlag(
        ConfigVariable.gitCache.argName,
        help:
            'Enable/Disable git cache globally, which is used for faster version installs. Defaults to true.',
        negatable: true,
      )
      ..addOption(
        ConfigVariable.fvmPath.argName,
        help: 'Set custom path where $kPackageName will cache versions.',
      );
  }
  @override
  Future<int> run() async {
    // Flag if settings should be saved
    var shouldSave = false;

    EnvConfig current = ConfigRepository.load();

    if (wasParsed(ConfigVariable.flutterRepo.argName)) {
      final flutterRepo = stringArg(ConfigVariable.flutterRepo.argName);

      logger.info('Setting flutter repo to: ${yellow.wrap(flutterRepo)}');
      current = current.copyWith(flutterRepoUrl: flutterRepo);
      shouldSave = true;
    }

    if (wasParsed(ConfigVariable.gitCache.argName)) {
      final gitCache = boolArg(ConfigVariable.gitCache.argName);
      logger.info('Setting git cache to: ${yellow.wrap(gitCache.toString())}');
      current = current.copyWith(gitCache: gitCache);
      shouldSave = true;
    }

    if (wasParsed(ConfigVariable.fvmPath.argName)) {
      final fvmPath = stringArg(ConfigVariable.fvmPath.argName);
      logger.info('Setting fvm path to: ${yellow.wrap(fvmPath)}');
      current = current.copyWith(fvmPath: fvmPath);
      shouldSave = true;
    }

    // Save
    if (shouldSave) {
      logger.info('');
      final updateProgress = logger.progress('Saving settings');
      // Update settings
      try {
        ConfigRepository.save(current);
      } catch (error) {
        updateProgress.fail('Failed to save settings');
        rethrow;
      }
      updateProgress.complete('Settings saved.');
    } else {
      // How do I scape a file.path?

      logger
        ..info('FVM Configuration:')
        ..info('Located at ${ctx.configPath}')
        ..info('');

      final options = current.toMap();

      if (options.keys.isEmpty) {
        logger.info('No settings have been configured.');
      } else {
        // Print options and it's values
        for (var key in options.keys) {
          final value = options[key];
          if (value != null) {
            final valuePrint = yellow.wrap(value.toString());
            logger.info('$key: $valuePrint');
          }
        }
      }
    }

    return ExitCode.success.code;
  }
}
