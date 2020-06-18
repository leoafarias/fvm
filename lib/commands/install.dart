import 'package:args/command_runner.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/guards.dart';
import 'package:fvm/utils/version_installer.dart';

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
    Guards.isGitInstalled();
    if (argResults.arguments.isEmpty) {
      throw ExceptionMissingChannelVersion();
    }
    final version = argResults.arguments[0].toLowerCase();

    await installFlutterVersion(version);
  }
}
