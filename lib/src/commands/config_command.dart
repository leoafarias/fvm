import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../models/config_model.dart';
import '../services/config_repository.dart';
import '../utils/constants.dart';
import '../utils/context.dart';
import 'base_command.dart';

/// Fvm Config
class ConfigCommand extends BaseCommand {
  @override
  final name = 'config';

  @override
  final description = 'Set global configuration settings for FVM';

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

    void updateConfigKey<T>(ConfigKeys key, T value) {
      if (wasParsed(key.paramKey)) {
        final updatedMap = AppConfig.fromMap({key.name: value});
        ctx.loggerService.info(
          'Setting ${key.paramKey} to: ${yellow.wrap(value.toString())}',
        );

        ctx.loggerService.info(updatedMap.toString());
        updatedConfig = updatedConfig.merge(updatedMap);
      }
    }

    for (var key in ConfigKeys.values) {
      updateConfigKey(key, argResults![key.paramKey]);
    }

    // Save
    if (updatedConfig != currentConfig) {
      ctx.loggerService.info('');
      final updateProgress = ctx.loggerService.progress('Saving settings');
      // Update settings
      try {
        ConfigRepository.save(updatedConfig);
      } catch (error) {
        updateProgress.fail('Failed to save settings');
        rethrow;
      }
      updateProgress.complete('Settings saved.');
    } else {
      ctx.loggerService
        ..info('FVM Configuration:')
        ..info('Located at ${ctx.configPath}')
        ..info('');

      final options = currentConfig.toMap();

      if (options.keys.isEmpty) {
        ctx.loggerService.info('No settings have been configured.');
      } else {
        // Print options and it's values
        for (var key in options.keys) {
          final value = options[key];
          if (value != null) {
            final valuePrint = yellow.wrap(value.toString());
            ctx.loggerService.info('$key: $valuePrint');
          }
        }
      }
    }

    return ExitCode.success.code;
  }
}
