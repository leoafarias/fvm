import 'package:args/command_runner.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/workflows/flutter_setup.workflow.dart';

import 'package:fvm/src/workflows/install_version.workflow.dart';

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
    final skipSetup = argResults['skip-setup'] == true;

    final project = await FlutterProjectRepo.findAncestor();
    // If no version was passed as argument check project config.
    if (argResults.arguments.isEmpty) {
      final configVersion = project.pinnedVersion;
      // If no config found is version throw error
      if (configVersion == null) {
        throw const UsageError('Please provide a channel or a version.');
      }
      // hasConfig = true;
      version = configVersion;
    } else {
      version = argResults.arguments[0];
    }
    final validVersion = await inferFlutterVersion(version);

    await installWorkflow(validVersion);
    if (!skipSetup) {
      await flutterSetupWorkflow(validVersion);
    }
  }
}
