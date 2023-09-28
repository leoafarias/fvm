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
        ConfigKeys.flutterUrl.paramKey,
        help: 'ADVANCED: Set Flutter repo url to clone from.',
      )
      ..addFlag(
        ConfigKeys.useGitCache.paramKey,
        help:
            'Enable/Disable git cache globally, which is used for faster version installs. Defaults to true.',
        negatable: true,
      )
      ..addOption(
        ConfigKeys.cachePath.paramKey,
        help: 'Set custom path where $kPackageName will cache versions.',
      );
  }
  @override
  Future<int> run() async {
    // Flag if settings should be saved
    var shouldSave = false;

    var current = ConfigRepository.loadFile();

    if (wasParsed(ConfigKeys.flutterUrl.paramKey)) {
      final flutterRepo = stringArg(ConfigKeys.flutterUrl.paramKey);

      logger.info('Setting flutter repo to: ${yellow.wrap(flutterRepo)}');
      current = current.copyWith(flutterUrl: flutterRepo);
      shouldSave = true;
    }

    if (wasParsed(ConfigKeys.useGitCache.paramKey)) {
      final gitCache = boolArg(ConfigKeys.useGitCache.paramKey);
      logger.info('Setting git cache to: ${yellow.wrap(gitCache.toString())}');
      current = current.copyWith(useGitCache: gitCache);
      shouldSave = true;
    }

    if (wasParsed(ConfigKeys.cachePath.paramKey)) {
      final cachePath = stringArg(ConfigKeys.cachePath.paramKey);
      logger.info('Setting fvm path to: ${yellow.wrap(cachePath)}');
      current = current.copyWith(cachePath: cachePath);
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
