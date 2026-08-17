import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:yaml_writer/yaml_writer.dart';

import '../models/config_model.dart';
import '../services/configuration_service.dart';
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

  String? _parsedString(ConfigOptions option) => wasParsed(option.paramKey)
      ? argResults![option.paramKey] as String?
      : null;

  bool? _parsedBool(ConfigOptions option) =>
      wasParsed(option.paramKey) ? argResults![option.paramKey] as bool? : null;

  @override
  Future<int> run() async {
    final current = LocalAppConfig.read(
      path: context.appConfigPath,
      requireValid: true,
    );
    final cachePath = _parsedString(ConfigOptions.cachePath);
    final gitCachePath = _parsedString(ConfigOptions.gitCachePath);
    final flutterUrl = _parsedString(ConfigOptions.flutterUrl);
    final useGitCache = _parsedBool(ConfigOptions.useGitCache);
    final updateCheckEnabled = wasParsed('update-check')
        ? argResults!['update-check'] as bool
        : null;

    final changes = <String, Object?>{
      if (cachePath != null && cachePath != current.cachePath)
        ConfigOptions.cachePath.paramKey: cachePath,
      if (gitCachePath != null && gitCachePath != current.gitCachePath)
        ConfigOptions.gitCachePath.paramKey: gitCachePath,
      if (flutterUrl != null && flutterUrl != current.flutterUrl)
        ConfigOptions.flutterUrl.paramKey: flutterUrl,
      if (useGitCache != null && useGitCache != current.useGitCache)
        ConfigOptions.useGitCache.paramKey: useGitCache,
      if (updateCheckEnabled != null &&
          !updateCheckEnabled != current.disableUpdateCheck)
        'update-check': updateCheckEnabled,
    };
    for (final entry in changes.entries) {
      logger.info(
        'Setting ${entry.key} to: ${yellow.wrap(entry.value?.toString())}',
      );
    }

    if (changes.isNotEmpty) {
      logger.info('');
      final updateProgress = logger.progress('Saving settings');
      try {
        get<ConfigurationService>().save(ConfigurationTarget.global, (
          cachePath: cachePath,
          gitCachePath: gitCachePath,
          flutterUrl: flutterUrl,
          runPubGetOnSdkChanges: null,
          updateVscodeSettings: null,
          updateGitIgnore: null,
          updateMelosSettings: null,
          useGitCache: useGitCache,
          updateCheckEnabled: updateCheckEnabled,
        ));
      } catch (error) {
        updateProgress.fail('Failed to save settings');
        rethrow;
      }
      updateProgress.complete('Settings saved.');

      return ExitCode.success.code;
    }

    logger
      ..info('FVM Configuration:')
      ..info('Located at ${context.appConfigPath}')
      ..info('');

    if (current.isEmpty) {
      logger.info('No settings have been configured.');

      return ExitCode.success.code;
    }

    logger.info(YamlWriter().write(current.toMap()));

    return ExitCode.success.code;
  }
}
