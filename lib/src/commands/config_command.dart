import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../models/config_model.dart';
import '../utils/constants.dart';
import 'base_command.dart';

/// Fvm Config
class ConfigCommand extends BaseFvmCommand {
  @override
  final name = 'config';

  @override
  final description = 'Set global configuration settings for FVM';

  /// Constructor
  ConfigCommand(super.context) {
    ConfigOptions.injectArgParser(argParser);
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
    final globalConfig = LocalAppConfig.read().toMap();
    bool hasChanges = false;

    void updateConfigKey<T>(ConfigOptions key, T value) {
      if (wasParsed(key.paramKey)) {
        logger.info(
          'Setting ${key.paramKey} to: ${yellow.wrap(value.toString())}',
        );

        if (globalConfig[key.name] != value) {
          globalConfig[key.name] = value;
          hasChanges = true;
        }
      }
    }

    for (var key in ConfigOptions.values) {
      updateConfigKey(key, argResults![key.paramKey]);
    }

    // Save
    if (hasChanges) {
      logger.info('');
      final updateProgress = logger.progress('Saving settings');
      // Update settings
      try {
        LocalAppConfig.fromMap(globalConfig).save();
      } catch (error) {
        updateProgress.fail('Failed to save settings');
        rethrow;
      }
      updateProgress.complete('Settings saved.');
    } else {
      logger
        ..info('FVM Configuration:')
        ..info('Located at ${context.config}')
        ..info('');

      if (globalConfig.keys.isEmpty) {
        logger.info('No settings have been configured.');
      } else {
        // Print options and it's values
        for (var key in globalConfig.keys) {
          final value = globalConfig[key];
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
