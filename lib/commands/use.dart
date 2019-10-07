import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:console/console.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';

/// Use an installed SDK version
class UseCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "use";
  final description = "Which Flutter SDK Version you would like to use";

  /// Constructor
  UseCommand() {
    argParser
      ..addOption('channel', abbr: 'c', help: 'Fluter channel to use ')
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Version number to use. i.e: 1.8.1',
      );
  }

  Future<void> run() async {
    final channel = argResults['channel'];
    final version = argResults['version'];

    final versionChoice = channel ?? version;

    // If channel or version was sent and its a valid Flutter channel
    if ((versionChoice != null) && await isValidFlutterInstall(versionChoice)) {
      return await linkProjectFlutterDir(versionChoice);
    }

    throw Exception('SDK: $versionChoice is not installed');
  }
}
