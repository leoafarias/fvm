import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../models/config_model.dart';
import '../services/config_repository.dart';
import '../services/logger_service.dart';
import '../utils/constants.dart';
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
      defaultsTo: true,
      negatable: true,
    );
  }
  @override
  Future<int> run() async {
    // Flag if settings should be saved

    final currentConfig = ConfigRepository.loadAppConfig();
    var updatedConfig = currentConfig;

    // TODO: Consolidate redundant code

    if (wasParsed(ConfigKeys.flutterUrl.paramKey)) {
      final flutterRepo = stringArg(ConfigKeys.flutterUrl.paramKey);
      logger.info('Setting flutter repo to: ${yellow.wrap(flutterRepo)}');
      // current.flutterUrl = flutterRepo;
      updatedConfig = currentConfig.copyWith(flutterUrl: flutterRepo);
    }

    if (wasParsed(ConfigKeys.gitCachePath.paramKey)) {
      final gitCachePath = stringArg(ConfigKeys.gitCachePath.paramKey);
      logger.info('Setting git cache path to: ${yellow.wrap(gitCachePath)}');
      // currentConfig.gitCachePath = gitCachePath;
      updatedConfig = currentConfig.copyWith(gitCachePath: gitCachePath);
    }

    if (wasParsed(ConfigKeys.useGitCache.paramKey)) {
      final gitCache = boolArg(ConfigKeys.useGitCache.paramKey);
      logger.info(
        'Setting use git cache to: ${yellow.wrap(gitCache.toString())}',
      );
      updatedConfig = currentConfig.copyWith(useGitCache: gitCache);
    }

    if (wasParsed(ConfigKeys.cachePath.paramKey)) {
      final cachePath = stringArg(ConfigKeys.cachePath.paramKey);
      logger.info('Setting fvm path to: ${yellow.wrap(cachePath)}');
      updatedConfig = currentConfig.copyWith(cachePath: cachePath);
    }

    if (wasParsed(ConfigKeys.priviledgedAccess.paramKey)) {
      final priviledgedAccess = boolArg(ConfigKeys.priviledgedAccess.paramKey);
      logger.info(
        'Setting priviledged access to: ${yellow.wrap(priviledgedAccess.toString())}',
      );
      updatedConfig =
          currentConfig.copyWith(priviledgedAccess: priviledgedAccess);
    }

    // Save
    if (updatedConfig != currentConfig) {
      logger.info('');
      final updateProgress = logger.progress('Saving settings');
      // Update settings
      try {
        ConfigRepository.save(currentConfig);
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

      final options = currentConfig.toMap();

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
