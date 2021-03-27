import 'package:args/command_runner.dart';

import 'package:fvm/constants.dart';

import 'package:fvm/src/services/flutter_tools.dart';

import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/utils/messages.dart';

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
            'Sets version as the global version.\nMake sure Flutter PATH env is set to: $kGlobalFlutterPath',
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

    // Show chooser if not version is provided
    if (argResults.rest.isEmpty) {
      /// Ask which version to select
      version = await cacheVersionSelector();
    }

    // Get version from first arg
    version ??= argResults.rest[0];

    final global = argResults['global'] == true;

    //TODO: Deprecation notice. Remove it later
    if (global) {
      FvmLogger.warning(Messages.UseGlobalDeprecation);
      return ExitCode.usage.code;
    }

    final force = argResults['force'] == true;

    // Get valid flutter version
    final validVersion = await FlutterTools.inferVersion(version);

    /// Run use workflow
    await useVersionWorkflow(
      validVersion,
      force: force,
    );

    return ExitCode.success.code;
  }
}
