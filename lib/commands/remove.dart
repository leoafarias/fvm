import 'package:args/command_runner.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';

/// Removes Flutter SDK
class RemoveCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "remove";
  final description = "Removes Flutter SDK Version";

  /// Constructor
  RemoveCommand() {
    argParser
      ..addOption('channel', abbr: 'c', help: 'Fluter channel to remove ')
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Version number to remove. i.e: 1.8.1',
      );
  }

  void run() async {
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
