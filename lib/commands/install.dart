import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';
import 'package:io/ansi.dart';

/// Installs Flutter SDK
class InstallCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "install";
  final description = "Installs Flutter SDK Version";

  /// Constructor
  InstallCommand();

  void run() async {
    final version = argResults.arguments[0];
    final isChannel = isValidFlutterChannel(version);

    final progress = logger.progress(green.wrap('Downloading $version'));
    try {
      if (isChannel) {
        await flutterChannelClone(version);
      } else {
        await flutterVersionClone(version);
      }
      finishProgress(progress);
    } on Exception {
      rethrow;
    }
  }
}
