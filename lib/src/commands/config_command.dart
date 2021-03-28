import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/src/services/fvm_settings_service.dart';
import 'package:fvm/src/utils/logger.dart';

import 'package:io/io.dart';

/// Fvm Config
class ConfigCommand extends Command<int> {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'config';

  @override
  final description = 'Set configuration for FVM';

  /// Constructor
  ConfigCommand() {
    argParser.addOption(
      'cache-path',
      help:
          'Set the path which FVM will cache the version. This will take precedence over FVM_HOME environment variable.',
    );
  }
  @override
  Future<int> run() async {
    final cachePath = argResults['cache-path'] as String;

    final settings = FvmSettingsService.readSync();
    if (cachePath != null) {
      settings.cachePath = cachePath;
      await FvmSettingsService.save(settings);
    }
    FvmLogger.spacer();
    FvmLogger.fine('FVM Settings:');
    FvmLogger.info('Located at ${kFvmSettings.path}');
    if (cachePath != null) {
      FvmLogger.spacer();
      FvmLogger.info('Cache Path: ${settings.cachePath}');
    }
    FvmLogger.spacer();
    return ExitCode.success.code;
  }
}
