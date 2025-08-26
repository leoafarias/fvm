import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason_logger/mason_logger.dart';

import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/helpers.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/use_version.workflow.dart';
import '../workflows/validate_flutter_version.workflow.dart';
import 'base_command.dart';

/// Use an installed SDK version
class UseCommand extends BaseFvmCommand {
  @override
  final name = 'use';

  @override
  String description = 'Sets the Flutter SDK version for the current project';

  UseCommand(super.context) {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Bypasses Flutter project validation checks',
        negatable: false,
      )
      ..addFlag(
        'pin',
        abbr: 'p',
        help:
            'Pins the latest release of a channel instead of using the channel directly',
        negatable: false,
      )
      ..addOption(
        'flavor',
        help: 'Sets the Flutter SDK version for a specific project flavor',
        defaultsTo: null,
        aliases: ['env'],
      )
      ..addFlag(
        'skip-pub-get',
        help: 'Skips running "flutter pub get" after switching SDK versions',
        defaultsTo: false,
        negatable: false,
      )
      ..addFlag(
        'skip-setup',
        abbr: 's',
        help: 'Skips downloading SDK dependencies after switching versions',
        negatable: false,
      );
  }
  @override
  Future<int> run() async {
    final forceOption = boolArg('force');
    final pinOption = boolArg('pin');
    final skipPubGet = boolArg('skip-pub-get');
    final flavorOption = stringArg('flavor');
    final skipSetup = boolArg('skip-setup');

    String? version;

    final useVersion = UseVersionWorkflow(context);
    final ensureCache = EnsureCacheWorkflow(context);
    final validateFlutterVersion = ValidateFlutterVersionWorkflow(context);
    final project = get<ProjectService>().findAncestor();

    // If no version was passed as argument check project config.
    if (argResults!.rest.isEmpty) {
      version = project.pinnedVersion?.name;
      final versions = await get<CacheService>().getAllVersions();
      // If no config found, ask which version to select.
      version ??= logger.cacheVersionSelector(versions);
    } else {
      // Get version from first arg
      version = firstRestArg;
    }

    // At this point, version could still be null, so we need to ensure it's not
    if (version == null) {
      throw UsageException(
        'Please provide a Flutter SDK version or run in a project with FVM configured.',
        usage,
      );
    }

    // Get valid flutter version. Force version if is to be pinned.
    if (pinOption) {
      if (!isFlutterChannel(version) || version == 'master') {
        throw UsageException(
          'Cannot pin a version that is not in dev, beta or stable channels.',
          usage,
        );
      }

      final releaseClient = get<FlutterReleaseClient>();

      final release = await releaseClient.getLatestChannelRelease(version);

      logger.info(
        'Pinning version ${release.version} from "$version" release channel...',
      );

      version = release.version;
    }

    // Gets flavor version
    final flavorVersion = project.flavors[version];

    if (flavorVersion != null) {
      if (flavorOption != null) {
        throw UsageException(
          'Cannot use the --flavor when using fvm use {flavor}',
          usage,
        );
      }

      logger.info(
        'Using Flutter SDK from flavor: "$version" which is "$flavorVersion"',
      );
      version = flavorVersion;
    }

    if (flavorOption != null) {
      // check if flavor option is not a channel name or semver
      if (isFlutterChannel(flavorOption)) {
        throw UsageException(
          'Cannot use a channel as a flavor, use a different name for flavor',
          usage,
        );
      }
    }

    final flutterVersion = validateFlutterVersion(version);

    final cacheVersion = await ensureCache(flutterVersion, force: forceOption);

    /// Run use workflow
    await useVersion(
      version: cacheVersion,
      project: project,
      force: forceOption,
      skipSetup: skipSetup,
      skipPubGet: skipPubGet,
      flavor: flavorOption,
    );

    return ExitCode.success.code;
  }

  @override
  String get invocation => 'fvm use {version}';
}
