import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:git/git.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' as io;

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/exceptions.dart';
import '../utils/helpers.dart';
import '../utils/parsers/git_clone_update_printer.dart';
import '../utils/run_command.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'global_version_service.dart';
import 'releases_service/releases_client.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterService extends Contextual {
  final CacheService _cacheService;
  final GlobalVersionService _globalVersionService;
  final FlutterReleasesService _flutterReleasesServices;
  final _dartCmd = 'dart';

  final _flutterCmd = 'flutter';

  FlutterService(
    super.context, {
    required CacheService cacheService,
    required GlobalVersionService globalVersionService,
    required FlutterReleasesService flutterReleasesServices,
  })  : _cacheService = cacheService,
        _globalVersionService = globalVersionService,
        _flutterReleasesServices = flutterReleasesServices;

  // Ensures cache.dir exists and its up to date
  Future<void> _ensureCacheDir() async {
    final isGitDir = await GitDir.isGitDir(context.gitCachePath);

    // If cache file does not exists create it
    if (!isGitDir) {
      await updateLocalMirror();
    }
  }

  /// Runs dart cmd
  Future<ProcessResult> _runOnVersion(
    String cmd,
    CacheFlutterVersion version,
    List<String> args, {
    bool? echoOutput,
    bool? throwOnError,
  }) async {
    final isFlutter = cmd == _flutterCmd;
    // Get exec path for dart
    final execPath = isFlutter ? version.flutterExec : version.dartExec;

    // Update environment
    final environment = updateEnvironmentVariables(
      [version.binPath, version.dartBinPath],
      context.environment,
      logger,
    );

    // Run command
    return await _runCmd(
      execPath,
      args: args,
      environment: environment,
      echoOutput: echoOutput,
      throwOnError: throwOnError,
    );
  }

  Future<ProcessResult> _runCmd(
    String execPath, {
    List<String> args = const [],
    Map<String, String>? environment,
    bool? echoOutput,
    bool? throwOnError,
  }) async {
    echoOutput ??= true;
    throwOnError ??= false;

    return await runCommand(
      execPath,
      args: args,
      environment: environment,
      throwOnError: throwOnError,
      echoOutput: echoOutput,
      context: context,
      logger: logger,
    );
  }

  List<String> _getArgs(String command) {
    var args = command;
    while (args.contains('  ')) {
      args = args.replaceAll('  ', ' ');
    }

    return args.split(' ');
  }

  /// Runs Flutter cmd
  Future<ProcessResult> runFlutter(
    List<String> args, {
    CacheFlutterVersion? version,
    bool? echoOutput,
    bool? throwOnError,
  }) {
    version ??= _globalVersionService.getGlobal();

    if (version == null) {
      return _runCmd(_flutterCmd, args: args);
    }

    return _runOnVersion(
      _flutterCmd,
      version,
      args,
      echoOutput: echoOutput,
      throwOnError: throwOnError,
    );
  }

  /// Runs dart cmd
  Future<ProcessResult> runDart(
    List<String> args, {
    CacheFlutterVersion? version,
    bool? echoOutput,
    bool? throwOnError,
  }) {
    version ??= _globalVersionService.getGlobal();

    if (version == null) {
      return _runCmd(_dartCmd, args: args);
    }

    return _runOnVersion(
      _dartCmd,
      version,
      args,
      echoOutput: echoOutput,
      throwOnError: throwOnError,
    );
  }

  /// Exec commands with the Flutter env
  Future<ProcessResult> execCmd(
    String execPath,
    List<String> args,
    CacheFlutterVersion? version,
  ) async {
    // Update environment variables
    // If execPath is not provided will get the path configured version
    var environment = context.environment;
    if (version != null) {
      environment = updateEnvironmentVariables(
        [version.binPath, version.dartBinPath],
        context.environment,
        logger,
      );
    }

    // Run command
    return await _runCmd(execPath, args: args, environment: environment);
  }

  /// Upgrades a cached channel
  Future<void> runUpgrade(CacheFlutterVersion version) async {
    if (version.isChannel) {
      await runFlutter(['upgrade'], version: version);
    } else {
      throw AppException('Can only upgrade Flutter Channels');
    }
  }

  /// Clones Flutter SDK from Version Number or Channel
  Future<void> install(
    FlutterVersion version, {
    required bool useGitCache,
  }) async {
    final versionDir = _cacheService.getVersionCacheDir(version.name);

    // Check if its git commit
    String? channel;

    if (version.isChannel) {
      channel = version.name;
      // If its not a commit hash
    } else if (version.isRelease) {
      if (version.releaseFromChannel != null) {
        // Version name forces channel version
        channel = version.releaseFromChannel;
      } else {
        final release =
            await _flutterReleasesServices.getReleaseFromVersion(version.name);
        channel = release?.channel.name;
      }
    }

    final versionCloneParams = [
      '-c',
      'advice.detachedHead=false',
      '-b',
      channel ?? version.name,
    ];

    final useMirrorParams = ['--reference', context.gitCachePath];

    final cloneArgs = [
      //if its a git hash
      if (!version.isCommit) ...versionCloneParams,
      if (useGitCache) ...useMirrorParams,
    ];

    try {
      final result = await runGit(
        [
          'clone',
          '--progress',
          ...cloneArgs,
          context.flutterUrl,
          versionDir.path,
        ],
        echoOutput: !(context.isTest || !logger.isVerbose),
      );

      final gitVersionDir = _cacheService.getVersionCacheDir(version.name);
      final isGit = await GitDir.isGitDir(gitVersionDir.path);

      if (!isGit) {
        throw AppException(
          'Flutter SDK is not a valid git repository after clone. Please try again.',
        );
      }

      /// If version is not a channel reset to version
      if (!version.isChannel) {
        final gitDir = await GitDir.fromExisting(gitVersionDir.path);
        // reset --hard $version
        await gitDir.runCommand(['reset', '--hard', version.version]);
      }

      if (result.exitCode != io.ExitCode.success.code) {
        throw AppException(
          'Could not clone Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
        );
      }
    } on Exception {
      _cacheService.remove(version);
      rethrow;
    }
  }

  /// Updates local Flutter repo mirror
  /// Will be used mostly for testing
  Future<void> updateLocalMirror() async {
    final isGitDir = await GitDir.isGitDir(context.gitCachePath);

    // If cache file does not exists create it
    if (isGitDir) {
      final gitDir = await GitDir.fromExisting(context.gitCachePath);
      logger.detail('Syncing local mirror...');

      try {
        await gitDir.runCommand(['pull', 'origin']);
      } on ProcessException catch (e) {
        logger.err(e.message);
      }
    } else {
      final gitCacheDir = Directory(context.gitCachePath);
      // Ensure brand new directory
      if (gitCacheDir.existsSync()) {
        gitCacheDir.deleteSync(recursive: true);
      }
      gitCacheDir.createSync(recursive: true);

      logger.info('Creating local mirror...');

      await runGitCloneUpdate(
        ['clone', '--progress', context.flutterUrl, gitCacheDir.path],
        logger,
      );
    }
  }

  /// Gets a commit for the Flutter repo
  /// If commit does not exist returns null
  Future<bool> isCommit(String commit) async {
    final commitSha = await getReference(commit);
    if (commitSha == null) {
      return false;
    }

    return commit.contains(commitSha);
  }

  /// Gets a tag for the Flutter repository
  /// If tag does not exist returns null
  Future<bool> isTag(String tag) async {
    final commitSha = await getReference(tag);
    if (commitSha == null) {
      return false;
    }

    final tags = await getTags();

    return tags.any((t) => t == tag);
  }

  Future<List<String>> getTags() async {
    await _ensureCacheDir();
    final isGitDir = await GitDir.isGitDir(context.gitCachePath);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    final gitDir = await GitDir.fromExisting(context.gitCachePath);
    final result = await gitDir.runCommand(['tag']);
    if (result.exitCode != 0) {
      return [];
    }

    return LineSplitter.split(result.stdout as String)
        .map((line) => line.trim())
        .toList();
  }

  Future<String?> getReference(String ref) async {
    await _ensureCacheDir();
    final isGitDir = await GitDir.isGitDir(context.gitCachePath);
    if (!isGitDir) {
      throw Exception('Git cache directory does not exist');
    }

    try {
      final gitDir = await GitDir.fromExisting(context.gitCachePath);
      final result = await gitDir.runCommand(
        ['rev-parse', '--short', '--verify', ref],
      );

      return result.stdout.trim();
    } on Exception {
      return null;
    }
  }
}
