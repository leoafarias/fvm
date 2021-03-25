import 'package:args/command_runner.dart';

import 'package:fvm/constants.dart';

import 'package:fvm/src/flutter_tools/flutter_helpers.dart';

import 'package:fvm/src/utils/pubdev.dart';

import 'package:fvm/src/workflows/use_version.workflow.dart';
import 'package:io/io.dart';

/// Use an installed SDK version
class UseCommand extends Command<int> {
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
  Future<int> run() async {
    String version;

    // If no version return error
    //TODO: Provide version selection
    if (argResults.rest.isEmpty) {
      throw Exception('Please provide a version to use');
    }

    version ??= argResults.rest[0];

    final global = argResults['global'] == true;
    final force = argResults['force'] == true;

    // Get valid flutter version
    final validVersion = await inferFlutterVersion(version);

    await useVersionWorkflow(validVersion, global: global, force: force);

    await checkIfLatestVersion();

    return ExitCode.success.code;
  }
}
