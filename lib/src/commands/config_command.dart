import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:yaml_writer/yaml_writer.dart';

import '../models/config_model.dart';
import 'base_command.dart';

/// Fvm Config
class ConfigCommand extends BaseFvmCommand {
  @override
  final name = 'config';

  @override
  final description = 'Configure global FVM settings and preferences';

  ConfigCommand(super.context) {
    ConfigOptions.injectArgParser(argParser);
    argParser.addFlag(
      'update-check',
      help: 'Enables or disables automatic update checking for FVM',
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

    if (wasParsed('update-check')) {
      final updateCheckEnabled = argResults!['update-check'] as bool;
      final disableUpdateCheck = !updateCheckEnabled;

      logger.info(
        'Setting update-check to: ${yellow.wrap(updateCheckEnabled.toString())}',
      );

      if (globalConfig['disableUpdateCheck'] != disableUpdateCheck) {
        globalConfig['disableUpdateCheck'] = disableUpdateCheck;
        hasChanges = true;
      }
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

    final yamlWriter = YamlWriter();
    final yamlString = yamlWriter.write(config.toMap());

    logger.info(yamlString);

    return ExitCode.success.code;
  }
}
