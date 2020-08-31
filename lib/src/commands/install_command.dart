import 'package:args/command_runner.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';

import 'package:fvm/src/utils/installer.dart';
import 'package:fvm/src/utils/pretty_print.dart';

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
    String version;
    var hasConfig = false;
    final skipSetup = argResults['skip-setup'] == true;

    final project = await FlutterProjectRepo().findOne();

    if (argResults.arguments.isEmpty) {
      final configVersion = project.pinnedVersion;
      if (configVersion == null) {
        throw ExceptionMissingChannelVersion();
      }
      hasConfig = true;
      version = configVersion;
    } else {
      version = argResults.arguments[0].toLowerCase();
    }

    final flutterVersion = await inferFlutterVersion(version);

    await installRelease(flutterVersion, skipSetup: skipSetup);

    if (hasConfig) {
      await project.setVersion(version);
      PrettyPrint.success('Project now uses Flutter: $version');
    }
  }
}
