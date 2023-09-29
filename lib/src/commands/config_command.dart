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
    ConfigKeys.injectArgParser(argParser);
    argParser.addFlag(
      'update-check',
      help: 'Checks if there is a new version of $kPackageName available.',
      negatable: true,
      defaultsTo: true,
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
      current.flutterUrl = flutterRepo;

      shouldSave = true;
    }

    if (wasParsed(ConfigKeys.gitCachePath.paramKey)) {
      final gitCachePath = stringArg(ConfigKeys.gitCachePath.paramKey);
      logger.info('Setting git cache path to: ${yellow.wrap(gitCachePath)}');
      current.gitCachePath = gitCachePath;
      shouldSave = true;
    }

    if (wasParsed(ConfigKeys.useGitCache.paramKey)) {
      final gitCache = boolArg(ConfigKeys.useGitCache.paramKey);
      logger.info(
        'Setting use git cache to: ${yellow.wrap(gitCache.toString())}',
      );
      current.useGitCache = gitCache;
      shouldSave = true;
    }

    if (wasParsed(ConfigKeys.cachePath.paramKey)) {
      final cachePath = stringArg(ConfigKeys.cachePath.paramKey);
      logger.info('Setting fvm path to: ${yellow.wrap(cachePath)}');
      current.cachePath = cachePath;
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
