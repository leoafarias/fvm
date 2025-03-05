import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../models/config_model.dart';
import '../utils/constants.dart';
import '../utils/pretty_json.dart';
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

    print(globalConfig);

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

      return ExitCode.success.code;
    }

    final config = LocalAppConfig.read();

    logger
      ..info('FVM Configuration:')
      ..info('Located at ${config.location}')
      ..info('');

    if (config.isEmpty) {
      logger.info('No settings have been configured.');

      return ExitCode.success.code;
    }

    logger.info(prettyJson(config.toMap()));

    return ExitCode.success.code;
  }
}
