import 'package:args/command_runner.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:io/io.dart';

import '../../exceptions.dart';
import '../services/flutter_tools.dart';
import '../utils/console_utils.dart';
import '../utils/messages.dart';
import '../workflows/use_version.workflow.dart';

/// Use an installed SDK version
class UseCommand extends Command<int> {
  @override
  final name = 'use';

  @override
  String description = 'Which Flutter SDK Version you would like to use';

  @override
  String get invocation => 'fvm use <version>';

  /// Constructor
  UseCommand() {
    // DEPRECATED: Global is Deprecated remove it later
    argParser
      ..addFlag(
        'global',
        help: 'Deprecated: Use "fvm global <version>"',
        negatable: false,
        callback: (flag) {
          if (!flag) return;
          throw const FvmUsageException(Messages.useGlobalDeprecation);
        },
      )
      ..addFlag(
        'force',
        help: 'Skips command guards that does Flutter project checks.',
        abbr: 'f',
        negatable: false,
      )
      ..addFlag(
        'pin',
        help:
            '''If version provided is a channel. Will pin the release version of the channel''',
        abbr: 'p',
        negatable: false,
      )
      ..addOption(
        'env',
        help: 'Project environment you want to use this version in',
        abbr: 'e',
        defaultsTo: null,
      );
  }
  @override
  Future<int> run() async {
    // final global = argResults['global'] == true;
    final forceOption = argResults['force'] == true;
    final pinOption = argResults['pin'] == true;
    final envOption = argResults['env'] as String;

    String version;

    // Show chooser if not version is provided
    if (argResults.rest.isEmpty) {
      /// Ask which version to select
      version = await cacheVersionSelector();
    }

    // Get version from first arg
    version ??= argResults.rest[0];

    // throw UsageException('Usage exception', usage.);

    // Get valid flutter version. Force version if is to be pinned.
    final validVersion = await FlutterTools.inferValidVersion(
      version,
      forceRelease: pinOption,
    );

    /// Cannot pin master channel
    if (pinOption && validVersion.isMaster) {
      throw FvmUsageException('Cannot pin a version from "master" channel.');
    }

    /// Print pin message if its pinning
    if (pinOption && checkIsChannel(version)) {
      FvmLogger.info(
        'Pinning version $validVersion fron "$version" release channel...',
      );
    }

    /// Run use workflow
    await useVersionWorkflow(
      validVersion,
      force: forceOption,
      environment: envOption,
    );

    return ExitCode.success.code;
  }
}
