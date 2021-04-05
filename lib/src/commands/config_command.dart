import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../services/context.dart';
import '../services/settings_service.dart';
import '../utils/logger.dart';
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
            'Priority over FVM_HOME.',
        abbr: 'c',
      )
      ..addFlag(
        'skip-setup',
        help: '''Will skip setup after a version install.''',
        abbr: 's',
        negatable: true,
        defaultsTo: null,
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
    final settings = SettingsService.readSync();

    // Flag if settings should be saved
    var shouldSave = false;

    // Cache path was set
    if (argResults.wasParsed('cache-path')) {
      settings.cachePath = stringArg('cache-path');
      shouldSave = true;
    }

    // Git cache option has changed
    if (argResults.wasParsed('git-cache')) {
      settings.gitCache = boolArg('git-cache');
      shouldSave = true;
    }

    // Skip setup option has changed
    if (argResults.wasParsed('skip-setup')) {
      settings.skipSetup = boolArg('skip-setup');
      shouldSave = true;
    }

    // Save
    if (shouldSave) {
      await SettingsService.save(settings);
      FvmLogger.fine('Settings saved.');
    } else {
      FvmLogger.spacer();
      FvmLogger.fine('FVM Settings:');
      FvmLogger.info('Located at ${ctx.settingsFile.path}');
      FvmLogger.spacer();

      final options = settings.toMap();

      if (options.keys.isEmpty) {
        FvmLogger.info('No settings have been configured.');
      } else {
        // Print options and it's values
        for (var key in options.keys) {
          final value = options[key];
          if (value != null) {
            final valuePrint = yellow.wrap(value.toString());
            FvmLogger.info('$key: $valuePrint');
          }
        }
      }

      FvmLogger.spacer();
    }

    return ExitCode.success.code;
  }
}
