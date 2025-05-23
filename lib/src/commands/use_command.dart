import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

import '../services/project_service.dart';
import '../services/releases_service/releases_client.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../workflows/use_version.workflow.dart';
import 'base_command.dart';

/// Use an installed SDK version
class UseCommand extends BaseFvmCommand {
  @override
  final name = 'use';

  @override
  String description =
      'Sets Flutter SDK Version you would like to use in a project';

  /// Constructor
  UseCommand(super.context) {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Skips command guards that does Flutter project checks.',
        negatable: false,
      )
      ..addFlag(
        'pin',
        abbr: 'p',
        help:
            'If version provided is a channel. Will pin the latest release of the channel',
        negatable: false,
      )
      ..addOption(
        'flavor',
        help: 'Sets version for a project flavor',
        defaultsTo: null,
        aliases: ['env'],
      )
      ..addFlag(
        'skip-pub-get',
        help: 'Skip resolving dependencies after switching Flutter SDK',
        defaultsTo: false,
        negatable: false,
      )
      ..addFlag(
        'skip-setup',
        abbr: 's',
        help: 'Skips Flutter setup after install',
        negatable: false,
      );
  }

  // Removed test-only code that was causing compiler errors

  /// Validates flavor name with comprehensive checks
  ///
  /// The flavor name should:
  /// - Start with a letter and contain only alphanumeric, underscore, and hyphen characters
  /// - Not be a Flutter channel name (to prevent confusion)
  /// - Not be a semver version (to prevent confusion with Flutter versions)
  /// - Not be a git commit hash (to prevent confusion with Flutter commits)
  /// - Not be a reserved word (to prevent confusion with FVM concepts)
  ///
  /// Throws [UsageException] if the flavor name is invalid
  void _validateFlavorName(String flavorName) {
    // Basic format validation - start with letter, alphanumeric + underscore/hyphen
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(flavorName)) {
      throw UsageException(
        'Flavor name must start with a letter and contain only letters, numbers, underscores, and hyphens',
        usage,
      );
    }

    // Prevent confusion with Flutter channels (essential reserved keywords)
    if (kFlutterChannels.contains(flavorName.toLowerCase())) {
      throw UsageException(
        'Cannot use Flutter channel name "$flavorName" as a flavor name. '
        'Channel names (${kFlutterChannels.join(', ')}) are reserved.',
        usage,
      );
    }

    // Prevent confusion with semver versions
    if (RegExp(r'^\d+\.\d+\.\d+').hasMatch(flavorName)) {
      throw UsageException(
        'Flavor name must start with a letter and contain only letters, numbers, underscores, and hyphens',
        usage,
      );
    }

    // Prevent confusion with git commit hashes (long hex strings)
    if (RegExp(r'^[a-fA-F0-9]{8,}$').hasMatch(flavorName)) {
      throw UsageException(
        'Flavor name must start with a letter and contain only letters, numbers, underscores, and hyphens',
        usage,
      );
    }

    // Prevent confusion with reserved words
    final reservedWords = ['flutter', 'version', 'cache', 'fvm'];
    if (reservedWords.contains(flavorName.toLowerCase())) {
      throw UsageException(
        'Flavor name must start with a letter and contain only letters, numbers, underscores, and hyphens',
        usage,
      );
    }
  }

  /// Exposed for testing only - validates a flavor name
  /// See [_validateFlavorName] for full documentation
  @visibleForTesting
  void validateFlavorNameForTesting(String flavorName) {
    _validateFlavorName(flavorName);
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
    final project = get<ProjectService>().findAncestor();

    // If no version was passed as argument check project config.
    if (argResults!.rest.isEmpty) {
      version = project.pinnedVersion?.name;
    }

    // Get version from first arg
    version ??= argResults!.rest[0];

    // Get valid flutter version. Force version if is to be pinned.
    if (pinOption) {
      // Check if it's one of the pinnable channels (stable, beta, dev)
      if (!isPinnableFlutterChannel(version)) {
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

    // Check if the version argument is actually a flavor name
    if (project.flavors.containsKey(version)) {
      // Using a flavor name as the version argument
      final flavorVersion = project.flavors[version];

      if (flavorOption != null) {
        throw UsageException(
          'Cannot use the --flavor option when using "fvm use {flavor}" syntax',
          usage,
        );
      }

      if (flavorVersion != null) {
        logger.info(
          'Using Flutter SDK from flavor: "$version" which is "$flavorVersion"',
        );
        version = flavorVersion;
      } else {
        throw UsageException(
          'The flavor "$version" exists but has no associated Flutter version',
          usage,
        );
      }
    } else if (flavorOption != null) {
      // Validate that the flavor name is not the same as the version being used
      // This would create a circular reference
      if (flavorOption == version) {
        throw UsageException(
          'Cannot use the same name for both flavor and version: "$version"',
          usage,
        );
      }

      // Validate the flavor name with more comprehensive checks
      _validateFlavorName(flavorOption);
    }

    final cacheVersion =
        await resolveAndEnsureVersion(version, force: forceOption);

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
