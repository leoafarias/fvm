import 'package:args/command_runner.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:io/io.dart';

import '../models/flutter_version_model.dart';
import '../utils/console_utils.dart';
import '../utils/logger.dart';
import '../workflows/use_version.workflow.dart';
import 'base_command.dart';

/// Use an installed SDK version
class UseCommand extends BaseCommand {
  @override
  final name = 'use';

  @override
  String description =
      'Sets Flutter SDK Version you would like to use in a project';

  @override
  String get invocation => 'fvm use {version}';

  /// Constructor
  UseCommand() {
    argParser
      ..addFlag(
        'force',
        help: 'Skips command guards that does Flutter project checks.',
        abbr: 'f',
        negatable: false,
      )
      ..addFlag(
        'pin',
        help:
            '''If version provided is a channel. Will pin the latest release of the channel''',
        abbr: 'p',
        negatable: false,
      )
      ..addOption(
        'flavor',
        help: 'Sets version for a project flavor',
        defaultsTo: null,
      );
  }
  @override
  Future<int> run() async {
    final forceOption = boolArg('force');
    final pinOption = boolArg('pin');
    final flavorOption = stringArg('flavor');

    String? version;

    // If no version was passed as argument check project config.
    if (argResults!.rest.isEmpty) {
      version = await ProjectService.findVersion();

      // If no config found, ask which version to select.
      version ??= await cacheVersionSelector();
    }

    // Get version from first arg
    version ??= argResults!.rest[0];

    // Get valid flutter version. Force version if is to be pinned.
    var validVersion = FlutterVersion(version);

    /// Cannot pin master channel
    if (pinOption && validVersion.isMaster) {
      throw UsageException(
        'Cannot pin a version from "master" channel.',
        usage,
      );
    }

    /// Pin release to channel
    if (pinOption && validVersion.isChannel) {
      logger.info(
        'Pinning version $validVersion fron "$version" release channel...',
      );

      final release = await FlutterReleasesClient.getLatestReleaseOfChannel(
          FlutterChannel.fromName(version));

      validVersion = FlutterVersion.fromString(release.version);
    }

    /// Run use workflow
    await useVersionWorkflow(
      validVersion,
      force: forceOption,
      flavor: flavorOption,
    );

    return ExitCode.success.code;
  }
}
