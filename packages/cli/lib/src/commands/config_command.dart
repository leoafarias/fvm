import 'package:args/command_runner.dart';
import 'package:fvm/src/utils/settings.dart';

/// Fvm Config
class ConfigCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'config';

  @override
  final description = 'Set configuration for FVM';

  /// Constructor
  ConfigCommand() {
    argParser
      ..addOption(
        'cache-path',
        help:
            'Set the path which FVM will cache the version. This will take precedence over FVM_HOME environment variable.',
      );
  }
  @override
  Future<void> run() async {
    final cachePath = argResults['cache-path'] as String;

    print(cachePath);
    final config = Settings.readSync();
    if (cachePath != null) {
      config.cachePath = cachePath;
      await config.save();
    }
    print('Cache Path: ${config.cachePath}');
  }
}
