import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/utils/config_utils.dart';
import 'package:fvm/utils/logger.dart';
import 'package:io/ansi.dart';

/// Config fvm options.
class ConfigCommand extends Command {
  /// Constructor
  ConfigCommand();

  @override
  String get description => "Config fvm options";

  @override
  String get name => "config";

  run() {
    final args = argResults.arguments;
    _runArgs(args);
    exit(0);
  }

  _runArgs(List<String> args) {
    final key = args[0];

    if (key == "path") {
      final pathCommand = _PathCommand();
      if (args.length > 1) {
        pathCommand.setFlutterStoredPath(args[1]);
      } else {
        logger.stdout(pathCommand.usage);
        logger.stderr(
            '${red.wrap('You must enter a directory.')} Such as: fvm config path ~/fvm/versions');
      }
    } else if (key == "ls") {
      final message = ConfigUtils().displayAllConfig();
      if (!message.isEmpty) {
        logger.stdout(message);
      } else {
        logger.stdout("No configuration options.");
      }
    }
  }
}

class _PathCommand extends Command {
  @override
  String get description => "Config flutter path";

  @override
  String get name => "path";

  void setFlutterStoredPath(String path) {
    ConfigUtils().configFlutterStoredPath(path);
  }

  @override
  String get usage => "dfkjl";
}
