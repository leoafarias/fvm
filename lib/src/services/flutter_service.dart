import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/context.dart';
import '../utils/exceptions.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'git_service.dart';
import 'logger_service.dart';
import 'process_service.dart';
import 'releases_service/releases_client.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterService extends ContextualService {
  const FlutterService(super.context);

  Future<ProcessResult> _cloneSdk({
    required String source,
    required Directory versionDir,
    required FlutterVersion version,
    required String? channel,
    required bool echoOutput,
  }) {
    final args = [
      'clone',
      '--progress',
      if (Platform.isWindows) ...['-c', 'core.longpaths=true'],
      if (!version.isUnknownRef && channel != null) ...[
        '-c',
        'advice.detachedHead=false',
        '-b',
        channel,
      ],
      source,
      versionDir.path,
    ];

    return runGit(args, echoOutput: echoOutput);
  }

  bool _shouldUseLocalMirror(FlutterVersion version) {
    return context.gitCache && !version.fromFork;
  }

  /// Attempts a clone from the local mirror. Returns null on failure so the
  /// caller can fall back to the remote without duplicating the try/catch
  /// boilerplate.
  Future<ProcessResult?> _tryCloneFromMirror({
    required Directory versionDir,
    required FlutterVersion version,
    required String? channel,
    required bool echoOutput,
  }) async {
    try {
      final result = await _cloneSdk(
        source: context.gitCachePath,
        versionDir: versionDir,
        version: version,
        channel: channel,
        echoOutput: echoOutput,
      );
      await _updateOriginToFlutter(versionDir);

      return result;
    } on ProcessException catch (error) {
      // Git corruption typically returns exit code 128; also check message.
      final messageLower = error.message.toLowerCase();
      final isLikelyCorruption = error.errorCode == 128 ||
          messageLower.contains('corrupt') ||
          messageLower.contains('damaged') ||
          messageLower.contains('bad object');

      if (isLikelyCorruption) {
        logger.err(
          'Local git cache appears corrupted '
          '(exit ${error.errorCode}: ${error.message}). '
          'Consider running "fvm doctor" to diagnose. '
          'Falling back to remote clone.',
        );
      } else {
        logger.warn(
          'Cloning from local git cache failed (${error.message}). '
          'Falling back to remote clone.',
        );
      }

      _cleanupPartialClone(versionDir);

      return null;
    }
  }

  void _cleanupPartialClone(Directory versionDir) {
    try {
      if (versionDir.existsSync()) {
        versionDir.deleteSync(recursive: true);
      }
    } on FileSystemException catch (e) {
      // Error level since this leaves orphaned directories that consume disk space
      logger.err(
        'Unable to clean up partial clone at ${versionDir.path}: ${e.message}. '
        'You may need to manually delete this directory.',
      );
    }
  }

  Future<void> _updateOriginToFlutter(Directory versionDir) async {
    await get<GitService>().setOriginUrl(
      repositoryPath: versionDir.path,
      url: context.flutterUrl,
    );
  }

  bool _isReferenceLookupError(String errorMessage) {
    final lower = errorMessage.toLowerCase();

    return lower.contains('unknown revision') ||
        lower.contains('ambiguous argument') ||
        lower.contains('not found');
  }

  Never _throwReferenceLookupError({
    required FlutterVersion version,
    required String repoUrl,
    required StackTrace stackTrace,
  }) {
    get<CacheService>().remove(version);

    final message = version.fromFork
        ? 'Reference "${version.version}" was not found in fork "${version.fork}".\n'
            'Please verify that this version exists in the forked repository.\n'
            'Repository URL: $repoUrl'
        : 'Reference "${version.version}" was not found in the Flutter repository.\n'
            'Please check that you have specified a valid version.\n'
            'Repository URL: $repoUrl';

    Error.throwWithStackTrace(AppException(message), stackTrace);
  }

  Future<void> _retryInstallFromRemote({
    required FlutterVersion version,
    required Directory versionDir,
    required String repoUrl,
    required String? channel,
    required bool echoOutput,
  }) async {
    logger.warn(
      'Reference "${version.version}" not found in local mirror. '
      'Retrying clone from remote repository...',
    );

    _cleanupPartialClone(versionDir);

    final retryResult = await _cloneSdk(
      source: repoUrl,
      versionDir: versionDir,
      version: version,
      channel: channel,
      echoOutput: echoOutput,
    );

    if (retryResult.exitCode != ExitCode.success.code) {
      throw AppException(
        'Could not clone Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
      );
    }

    // Validate reference in fresh clone (no retry this time)
    await _ensureReference(version: version, gitVersionDir: versionDir);
  }

  Future<void> _ensureReference({
    required FlutterVersion version,
    required Directory gitVersionDir,
  }) async {
    final gitDir = await GitDir.fromExisting(gitVersionDir.path);

    // Check if version is a remote branch
    final branchResult = await gitDir.runCommand([
      'branch',
      '-r',
      '--list',
      'origin/${version.version}',
    ]);

    final isBranch = (branchResult.stdout as String).trim().isNotEmpty;

    if (isBranch) {
      await gitDir.runCommand(['checkout', version.version]);
      logger.debug('Checked out branch: ${version.version}');
    } else {
      await get<GitService>().resetHard(gitVersionDir.path, version.version);
    }
  }

  Future<ProcessResult> run(
    String cmd,
    List<String> args,
    CacheFlutterVersion version, {
    bool throwOnError = false,
    bool? echoOutput,
  }) {
    final versionRunner = VersionRunner(context: context, version: version);

    return versionRunner.run(
      cmd,
      args,
      throwOnError: throwOnError,
      echoOutput: echoOutput,
    );
  }

  Future<ProcessResult> pubGet(
    CacheFlutterVersion version, {
    bool throwOnError = false,
    bool offline = false,
  }) {
    final args = ['pub', 'get', if (offline) '--offline'];

    // For offline mode, we can safely suppress output
    // For online mode, we need to allow stdio inheritance for authentication prompts
    return run(
      'flutter',
      args,
      version,
      throwOnError: throwOnError,
      echoOutput:
          !offline, // Allow stdio inheritance for authentication when online
    );
  }

  Future<ProcessResult> setup(CacheFlutterVersion version) {
    return run('flutter', ['--version'], version);
  }

  Future<ProcessResult> runFlutter(
    List<String> args,
    CacheFlutterVersion version,
  ) {
    return run('flutter', args, version);
  }

  Future<void> install(FlutterVersion version) async {
    // Get the version-specific cache directory using the FlutterVersion object
    final versionDir = get<CacheService>().getVersionCacheDir(version);

    // For fork versions, ensure the parent directory exists
    if (version.fromFork) {
      final forkDir = Directory(
        path.join(context.versionsCachePath, version.fork!),
      );
      if (!forkDir.existsSync()) {
        forkDir.createSync(recursive: true);
      }
      logger.debug('Created fork directory: ${forkDir.path}');
    }

    // Check if its git commit
    String? channel = version.name;

    if (version.isChannel) {
      channel = version.name;
    }
    if (version.isRelease) {
      if (version.releaseChannel != null) {
        // Version name forces channel version
        channel = version.releaseChannel!.name;
      } else {
        final release = await get<FlutterReleaseClient>().getReleaseByVersion(
          version.name,
        );

        if (release != null) {
          channel = release.channel.name;
        }
      }
    }

    // Determine which URL to use for cloning
    String repoUrl = context.flutterUrl;

    // If this is a forked version, use the fork's URL
    if (version.fromFork) {
      logger.debug('Installing from fork: ${version.fork}');

      try {
        repoUrl = context.getForkUrl(version.fork!);
        logger.info('Using forked repository URL: $repoUrl');
      } catch (e, stackTrace) {
        Error.throwWithStackTrace(
          AppException(
            'Fork "${version.fork}" not found in configuration. '
            'Please add it first using: fvm fork add ${version.fork} <url>',
          ),
          stackTrace,
        );
      }
    }

    final bool useLocalMirror = _shouldUseLocalMirror(version);
    final echoOutput = !(context.isTest || !logger.isVerbose);

    ProcessResult result;
    bool clonedFromMirror = false;

    try {
      if (useLocalMirror) {
        final mirrorResult = await _tryCloneFromMirror(
          versionDir: versionDir,
          version: version,
          channel: channel,
          echoOutput: echoOutput,
        );

        if (mirrorResult != null) {
          result = mirrorResult;
          clonedFromMirror = true;
        } else {
          result = await _cloneSdk(
            source: repoUrl,
            versionDir: versionDir,
            version: version,
            channel: channel,
            echoOutput: echoOutput,
          );
        }
      } else {
        result = await _cloneSdk(
          source: repoUrl,
          versionDir: versionDir,
          version: version,
          channel: channel,
          echoOutput: echoOutput,
        );
      }

      // Use FlutterVersion object with getVersionCacheDir
      final gitVersionDir = get<CacheService>().getVersionCacheDir(version);
      final isGit = await GitDir.isGitDir(gitVersionDir.path);

      if (!isGit) {
        throw AppException(
          'Flutter SDK is not a valid git repository after clone. Please try again.',
        );
      }

      /// If version is not a channel reset to version
      if (!version.isChannel) {
        try {
          await _ensureReference(
            version: version,
            gitVersionDir: gitVersionDir,
          );
        } on ProcessException catch (e, stackTrace) {
          if (clonedFromMirror && _isReferenceLookupError(e.message)) {
            await _retryInstallFromRemote(
              version: version,
              versionDir: versionDir,
              repoUrl: repoUrl,
              channel: channel,
              echoOutput: echoOutput,
            );
            // Successfully retried, continue with setup
          } else if (_isReferenceLookupError(e.message)) {
            _throwReferenceLookupError(
              version: version,
              repoUrl: repoUrl,
              stackTrace: stackTrace,
            );
          } else {
            rethrow;
          }
        }
      }

      if (result.exitCode != ExitCode.success.code) {
        throw AppException(
          'Could not clone Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
        );
      }
    } on ProcessException catch (e, stackTrace) {
      // Improved error message for clone failures
      String errorMessage = e.toString().toLowerCase();

      // Simplify clone error detection
      if (errorMessage.contains('repository not found') ||
          errorMessage.contains('remote branch') &&
              errorMessage.contains('not found')) {
        get<CacheService>().remove(version);

        if (version.fromFork) {
          Error.throwWithStackTrace(
            AppException(
              'Failed to clone fork "${version.fork}" with version "${version.version}".\n'
              'Please verify that the fork URL is correct and the version exists.\n'
              'Repository URL: $repoUrl',
            ),
            stackTrace,
          );
        }

        Error.throwWithStackTrace(
          AppException(
            'Failed to clone Flutter repository with version "${version.version}".\n'
            'The branch or tag does not exist in the upstream repository.\n'
            'Repository URL: $repoUrl',
          ),
          stackTrace,
        );
      }

      // Clean up and rethrow
      get<CacheService>().remove(version);
      rethrow;
    } on Exception {
      get<CacheService>().remove(version);
      rethrow;
    }
  }
}

class VersionRunner {
  final FvmContext _context;
  final CacheFlutterVersion _version;

  const VersionRunner({
    required FvmContext context,
    required CacheFlutterVersion version,
  })  : _context = context,
        _version = version;

  Map<String, String> _updateEnvironmentVariables(List<String> paths) {
    // Remove any values that are similar
    // within the list of paths.
    paths = paths.toSet().toList();

    final env = _context.environment;

    final logger = _context.get<Logger>();

    logger.debug('Starting to update environment variables...');

    final updatedEnvironment = Map.of(env);

    final envPath = env['PATH'] ?? '';

    final separator = Platform.isWindows ? ';' : ':';

    updatedEnvironment['PATH'] = paths.join(separator) + separator + envPath;

    return updatedEnvironment;
  }

  /// Runs dart cmd
  Future<ProcessResult> run(
    String cmd,
    List<String> args, {
    bool? echoOutput,
    bool? throwOnError,
  }) {
    // Update environment
    final environment = _updateEnvironmentVariables([
      _version.binPath,
      _version.dartBinPath,
    ]);

    // Run command
    return _context.get<ProcessService>().run(
          cmd,
          args: args,
          environment: environment,
          throwOnError: throwOnError ?? false,
          echoOutput: echoOutput ?? true,
        );
  }
}
