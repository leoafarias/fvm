import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/guards.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/project_config.dart';

/// Use an installed SDK version
class UseCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'use';

  @override
  final description = 'Which Flutter SDK Version you would like to use';

  /// Constructor
  UseCommand() {
    argParser
      ..addFlag(
        'global',
        help:
            'Sets version as the global version.\nMake sure Flutter PATH env is set to: $kDefaultFlutterPath',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    final useGlobally = argResults['global'] == true;
    final version = argResults.rest[0];

    if (argResults.rest.isEmpty) {
      throw Exception('Please provide a version. fvm use <version>');
    }
    // Make sure is valid Flutter version
    final flutterVersion = await inferFlutterVersion(version);
    // If project use check that is Flutter project
    if (!useGlobally) Guards.isFlutterProject();

    // Make sure version is installed
    await checkAndInstallVersion(flutterVersion);

    if (useGlobally) {
      // Sets version as the global
      setAsGlobalVersion(flutterVersion);
    } else {
      // Updates the project config with version
      setAsProjectVersion(flutterVersion);
    }
  }
}
