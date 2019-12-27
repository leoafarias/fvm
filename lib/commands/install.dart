import 'package:args/command_runner.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';
import 'package:io/ansi.dart';

/// Installs Flutter SDK
class InstallCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'install';

  @override
  final description = 'Installs Flutter SDK Version';

  /// Constructor
  InstallCommand();

  @override
  void run() async {
    await checkIfGitExists();
    if (argResults.arguments.isEmpty) {
      throw ExceptionMissingChannelVersion();
    }
    final version = argResults.arguments[0].toLowerCase();
    final isChannel = isValidFlutterChannel(version);

    final progress = logger.progress(green.wrap('Downloading $version'));
    if (isChannel) {
      await flutterChannelClone(version);
    } else {
      await flutterVersionClone(version);
    }
    finishProgress(progress);
  }
}
