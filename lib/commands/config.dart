import 'package:args/command_runner.dart';
import 'package:fvm/utils/print.dart';
import 'package:fvm/utils/config_utils.dart';

/// Config fvm options.
class ConfigCommand extends Command {
  @override
  String get name => 'config';

  @override
  String get description => 'Config fvm options';

  /// Constructor
  ConfigCommand() {
    argParser
      ..addOption('defaultVersion', abbr: 'd', help: 'Flutter default version')
      ..addOption('cache-path',
          abbr: 'c', help: 'Path to store Flutter cached versions')
      ..addFlag('ls', help: 'Lists all config options');
  }

  @override
  Future<void> run() async {
    final path = argResults['cache-path'] as String;
    if (path != null) {
      ConfigUtils().configFlutterStoredPath(path);
    }

    if (argResults['ls'] != null) {
      final configOptions = ConfigUtils().displayAllConfig();
      if (configOptions.isNotEmpty) {
        Print.success(configOptions);
      } else {
        throw Exception('No configuration has been set');
      }
    }
  }
}
