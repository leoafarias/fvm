import 'package:fvm/src/utils/logger.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../services/settings_service.dart';
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
        'cache-path',
        help: 'Set the path which FVM will cache the version.'
            ' Priority over FVM_HOME.',
        abbr: 'c',
      )
      ..addFlag(
        'git-cache',
        help: 'ADVANCED: Will cache a local version of'
            ' Flutter repo for faster version install.',
        abbr: 'g',
        negatable: true,
        defaultsTo: null,
      );
  }
  @override
  Future<int> run() async {
    // Flag if settings should be saved
    var shouldSave = false;

    // Cache path was set
    if (argResults!.wasParsed('cache-path')) {
      ctx.settings!.cachePath = stringArg('cache-path');
      shouldSave = true;
    }

    // Git cache option has changed
    if (argResults!.wasParsed('git-cache')) {
      ctx.settings!.gitCacheDisabled = !boolArg('git-cache');
      shouldSave = true;
    }

    // Save
    if (shouldSave) {
      final updateProgress = logger.progress('Saving settings');
      // Update settings
      try {
        await ctx.settings!.save();
      } catch (error) {
        updateProgress.fail('Failed to save settings');
        return ExitCode.config.code;
      }
      updateProgress.complete('Settings saved.');
    } else {
      logger
        ..info('')
        ..info('FVM Settings:')
        ..info('Located at ${SettingsService.settingsFile.path}')
        ..info('');

      final options = ctx.settings!.toMap();

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
