import 'package:args/command_runner.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/guards.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/project_config.dart';
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
  InstallCommand() {
    argParser
      ..addFlag(
        'skip-setup',
        help: 'Skips Flutter setup after install',
        negatable: false,
      );
  }

  @override
  void run() async {
    Guards.isGitInstalled();

    String version;
    if (argResults.arguments.isEmpty) {
      final configVersion = getConfigFlutterVersion();
      if (configVersion == null) {
        throw ExceptionMissingChannelVersion();
      }
      version = configVersion;
    } else {
      version = argResults.arguments[0].toLowerCase();
    }

    final skipSetup = argResults['skip-setup'] == true;

    final flutterVersion = await inferFlutterVersion(version);

    await installFlutterVersion(flutterVersion, skipSetup: skipSetup);
  }
}
