import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';

/// Installs Flutter SDK
class InstallCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "install";
  final description = "Installs Flutter SDK Version";

  /// Constructor
  InstallCommand() {
    argParser
      ..addOption('channel', abbr: 'c', help: 'Fluter channel to install ')
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Version number to install. i.e: 1.8.1',
      );
  }

  void run() async {
    final channel = argResults['channel'];
    final version = argResults['version'];

    final validChannel = isValidFlutterChannel(channel);
    // Add 'v' in front of version number due to Flutter pattern
    final validVersion = await isValidFlutterVersion(version);

    // If channel was sent and its a valid Flutter channel
    if (validChannel) {
      return await flutterChannelClone(channel);
    }

    if (validVersion) {
      return await flutterVersionClone(version);
    }

    if (channel != null && validChannel == false) {
      throw Exception('$channel is not a valid Flutter Channel');
    }

    if (version != null && validVersion == false) {
      throw Exception('$version is not a valid Flutter version');
    }
  }
}
