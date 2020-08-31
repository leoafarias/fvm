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
        'cachePath',
        help:
            'Set the path which FVM will cache the version. This will take precedence over FVM_HOME environment variable.',
      );
  }
  @override
  Future<void> run() async {
    final config = FvmSettings.read();
    config.cachePath = argResults['cachePath'] as String;
    await config.save();
  }
}
