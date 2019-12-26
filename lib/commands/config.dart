import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:fvm/utils/config_utils.dart';
import 'package:fvm/utils/logger.dart';

/// Config fvm options.
class ConfigCommand extends Command {
  String get name => "config";
  String get description => "Config fvm options";

  /// Constructor
  ConfigCommand() {
    argParser
      ..addOption('cache-path',
          abbr: 'c', help: 'Path to store Flutter cached versions')
      ..addFlag('ls', help: 'Lists all config options');
  }
  Future<void> run() async {
    final path = argResults['cache-path'];
    if (path != null) {
      ConfigUtils().configFlutterStoredPath(path);
    }

    if (argResults['ls']) {
      final configOptions = ConfigUtils().displayAllConfig();
      if (configOptions.isNotEmpty) {
        logger.stdout(green.wrap(configOptions));
      } else {
        throw 'No configuration has been set';
      }
    }
  }
}
