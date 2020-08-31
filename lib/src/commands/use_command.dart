import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';

import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/local_versions/local_version.repo.dart';
import 'package:fvm/src/local_versions/local_versions_tools.dart';

import 'package:fvm/src/utils/helpers.dart';

import 'package:fvm/src/utils/pretty_print.dart';
import 'package:fvm/src/utils/pubdev.dart';
import 'package:cli_dialog/cli_dialog.dart';

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
      )
      ..addFlag(
        'force',
        help: 'Skips command guards that does Flutter project checks.',
        negatable: false,
      );
  }
  @override
  Future<void> run() async {
    String version;

    // If no version is provider show selection
    if (argResults.rest.isEmpty) {
      final installedSdks = await LocalVersionRepo().getAll();
      if (installedSdks.isEmpty) {
        throw Exception('Please install a version. fvm install <version>');
      }
      final listQuestions = [
        [
          {
            'question': 'Select version',
            'options': installedSdks,
          },
          'version'
        ]
      ];
      final dialog = CLI_Dialog(listQuestions: listQuestions);
      final answer = dialog.ask();
      version = answer['version'] as String;
    }

    version ??= argResults.rest[0];
    final isGlobal = argResults['global'] == true;
    final isForced = argResults['force'] == true;

    // Make sure is valid Flutter version
    final flutterVersion = await inferFlutterVersion(version);
    final project = await FlutterProjectRepo().findOne();
    final isFlutterProject = await project.isFlutterProject();
    // If project use check that is Flutter project
    if (!isGlobal && !isForced && !isFlutterProject) {
      throw Exception(
          'Run this FVM command at the root of a Flutter project or use --force to bypass this.');
    }

    // Make sure version is installed
    await checkAndInstallVersion(flutterVersion);

    if (isGlobal) {
      // Sets version as the global
      setAsGlobalVersion(flutterVersion);
    } else {
      // Updates the project config with version

      await project.setVersion(flutterVersion);
    }

    PrettyPrint.success('Project now uses Flutter: $version');

    await checkIfLatestVersion();
  }
}
