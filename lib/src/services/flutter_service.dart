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
import '../utils/file_utils.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'git_service.dart';
import 'logger_service.dart';
import 'process_service.dart';
import 'releases_service/releases_client.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterService extends ContextualService {
  static const List<String> _gitObjectCorruptionMarkers = [
    'bad object',
    'loose object',
    'object file',
    'pack has bad object',
  ];

  static const List<String> _gitMissingObjectMarkers = [
    'reference is not a tree',
    'unable to read tree',
    'invalid object name',
    'missing blob',
    'missing tree',
  ];

  static const List<String> _gitObjectErrorPatterns = [
    ..._gitObjectCorruptionMarkers,
    ..._gitMissingObjectMarkers,
  ];

  /// Error markers for transient mirror availability issues (e.g., race
  /// during mirror swap or filesystem contention). These are retried once
  /// before falling back to the remote.
  static const List<String> _transientMirrorErrorMarkers = [
    'does not appear to be a git repository',
    'not a git repository',
    'no such file or directory',
    'repository does not exist',
  ];

  static const int _kMaxTransientMirrorRetries = 1;
  static const Duration _kTransientMirrorRetryDelay =
      Duration(milliseconds: 500);

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
  ///
  /// Transient availability errors (e.g., mirror mid-swap) are retried once
  /// before falling back. Corruption errors skip retry and trigger mirror
  /// removal.
  Future<ProcessResult?> _tryCloneFromMirror({
    required Directory versionDir,
    required FlutterVersion version,
    required String? channel,
    required bool echoOutput,
  }) async {
    for (var attempt = 0;
        attempt <= _kMaxTransientMirrorRetries;
        attempt++) {
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
        // Corruption: no retry, remove mirror and fall back immediately.
        if (_isMirrorCorruptionError(error.message)) {
          logger.warn(
            'Local git cache appears corrupted '
            '(exit ${error.errorCode}: ${error.message}). '
            'Falling back to remote clone.',
          );

          final cacheDir = Directory(context.gitCachePath);
          if (cacheDir.existsSync()) {
            final deleted = await get<GitService>().removeLocalMirror(
              requireSuccess: false,
              onFinalError: (error) {
                logger.warn(
                  'Could not remove corrupted cache: ${error.message}. '
                  'You may need to manually delete ${cacheDir.path}',
                );
              },
            );
            if (deleted) {
              logger.info(
                'Removed corrupted cache. '
                'It will be recreated on next install.',
              );
            }
          }

          await _cleanupInstallArtifacts(
            version: version,
            versionDir: versionDir,
            removeCache: false,
          );

          return null;
        }

        // Transient availability error: retry once before falling back.
        if (_isTransientMirrorError(error.message) &&
            attempt < _kMaxTransientMirrorRetries) {
          logger.warn(
            'Local mirror temporarily unavailable (${error.message}). '
            'Retrying after ${_kTransientMirrorRetryDelay.inMilliseconds}ms...',
          );
          await _cleanupPartialClone(versionDir);
          await Future.delayed(_kTransientMirrorRetryDelay);

          continue;
        }

        // Other failures: fall back to remote.
        logger.warn(
          'Cloning from local git cache failed (${error.message}). '
          'Falling back to remote clone.',
        );

        await _cleanupInstallArtifacts(
          version: version,
          versionDir: versionDir,
          removeCache: false,
        );

        return null;
      }
    }

    return null;
  }

  Future<void> _cleanupPartialClone(Directory versionDir) async {
    if (!versionDir.existsSync()) return;
    await deleteDirectoryWithRetry(
      versionDir,
      requireSuccess: false,
      onFinalError: (e) {
        // Warn level since cleanup failure is recoverable and execution continues
        logger.warn(
          'Unable to clean up partial clone at ${versionDir.path}: ${e.message}. '
          'You may need to manually delete this directory.',
        );
      },
    );
  }

  Future<void> _cleanupInstallArtifacts({
    required FlutterVersion version,
    required Directory versionDir,
    required bool removeCache,
  }) async {
    await _cleanupPartialClone(versionDir);

    if (removeCache) {
      await get<CacheService>().remove(version);
    }
  }

  Future<void> _updateOriginToFlutter(Directory versionDir) async {
    await get<GitService>().setOriginUrl(
      repositoryPath: versionDir.path,
      url: context.flutterUrl,
    );
  }

  /// Detects git errors indicating a reference (branch/tag/commit) doesn't exist.
  /// Used to determine if retry from remote is warranted.
  bool _isReferenceLookupError(String errorMessage) {
    final lower = errorMessage.toLowerCase();

    return lower.contains('unknown revision') ||
        lower.contains('ambiguous argument') ||
        lower.contains('not found');
  }

  /// Detects git errors that indicate missing or unreadable objects in the
  /// local mirror. These should trigger a retry from the remote.
  bool _isMissingObjectError(String errorMessage) {
    final lower = errorMessage.toLowerCase();

    return _gitObjectErrorPatterns.any(lower.contains);
  }

  bool _isMirrorCorruptionError(String errorMessage) {
    final lower = errorMessage.toLowerCase();

    if (lower.contains('corrupt') ||
        lower.contains('damaged') ||
        lower.contains('hash mismatch')) {
      return true;
    }

    return _gitObjectCorruptionMarkers.any(lower.contains);
  }

  /// Detects transient mirror availability errors (e.g., race during mirror
  /// swap or brief filesystem contention). These warrant a single retry.
  bool _isTransientMirrorError(String errorMessage) {
    final lower = errorMessage.toLowerCase();

    return _transientMirrorErrorMarkers.any(lower.contains);
  }

  Never _throwReferenceLookupError({
    required FlutterVersion version,
    required String repoUrl,
    required StackTrace stackTrace,
  }) {
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

    await _cleanupInstallArtifacts(
      version: version,
      versionDir: versionDir,
      removeCache: false,
    );

    if (versionDir.existsSync()) {
      throw AppException(
        'Cannot install version "${version.name}": failed to clean up '
        'partial clone at ${versionDir.path}. '
        'Please manually delete this directory and try again.',
      );
    }

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
    try {
      await _ensureReference(version: version, gitVersionDir: versionDir);
    } on ProcessException catch (error, stackTrace) {
      if (_isReferenceLookupError(error.message)) {
        _throwReferenceLookupError(
          version: version,
          repoUrl: repoUrl,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }

    // Bring the shared mirror up to date so future installs can use it.
    if (context.gitCache && !version.fromFork) {
      try {
        await get<GitService>().updateLocalMirror();
      } catch (e, stackTrace) {
        logger.debug('Mirror refresh after fallback failed: $e');
        logger.warn(
          'Failed to refresh local git mirror after remote clone; continuing. '
          'This may cause the next install to fetch from remote again.',
        );
        logger.debug(stackTrace.toString());
      }
    }
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

  Directory _setupCacheDirectories(FlutterVersion version) {
    final versionDir = get<CacheService>().getVersionCacheDir(version);

    if (version.fromFork) {
      final forkDir = Directory(
        path.join(context.versionsCachePath, version.fork!),
      );
      if (!forkDir.existsSync()) {
        forkDir.createSync(recursive: true);
      }
      logger.debug('Created fork directory: ${forkDir.path}');
    }

    return versionDir;
  }

  Future<String?> _resolveChannel(FlutterVersion version) async {
    String? channel = version.name;

    if (version.isChannel) {
      channel = version.name;
    }

    if (version.isRelease) {
      if (version.releaseChannel != null) {
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

    return channel;
  }

  String _resolveRepositoryUrl(FlutterVersion version) {
    String repoUrl = context.flutterUrl;

    if (version.fromFork) {
      logger.debug('Installing from fork: ${version.fork}');

      try {
        repoUrl = context.getForkUrl(version.fork!);
        logger.info('Using forked repository URL: $repoUrl');
      } catch (_, stackTrace) {
        Error.throwWithStackTrace(
          AppException(
            'Fork "${version.fork}" not found in configuration. '
            'Please add it first using: fvm fork add ${version.fork} <url>',
          ),
          stackTrace,
        );
      }
    }

    return repoUrl;
  }

  Future<_CloneOutcome> _executeClone({
    required FlutterVersion version,
    required Directory versionDir,
    required String repoUrl,
    required String? channel,
    required bool echoOutput,
  }) async {
    final bool useLocalMirror = _shouldUseLocalMirror(version);

    ProcessResult result;
    bool clonedFromMirror = false;

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
        if (versionDir.existsSync()) {
          throw AppException(
            'Cannot install version "${version.name}": failed to clean up '
            'partial clone at ${versionDir.path}. '
            'Please manually delete this directory and try again.',
          );
        }

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

    return _CloneOutcome(result: result, clonedFromMirror: clonedFromMirror);
  }

  Future<void> _validateReference({
    required FlutterVersion version,
    required Directory versionDir,
    required bool clonedFromMirror,
    required String repoUrl,
    required String? channel,
    required bool echoOutput,
  }) async {
    if (version.isChannel) return;

    try {
      await _ensureReference(version: version, gitVersionDir: versionDir);
    } on ProcessException catch (e, stackTrace) {
      final isReferenceError = _isReferenceLookupError(e.message);
      final isMissingObject = _isMissingObjectError(e.message);

      if (clonedFromMirror && (isReferenceError || isMissingObject)) {
        await _retryInstallFromRemote(
          version: version,
          versionDir: versionDir,
          repoUrl: repoUrl,
          channel: channel,
          echoOutput: echoOutput,
        );
      } else if (isReferenceError) {
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

  Future<void> _handleCloneError({
    required Object error,
    required StackTrace stackTrace,
    required FlutterVersion version,
    required Directory versionDir,
    required String repoUrl,
  }) async {
    if (error is ProcessException) {
      final errorMessage = error.toString().toLowerCase();

      if (errorMessage.contains('repository not found') ||
          (errorMessage.contains('remote branch') &&
              errorMessage.contains('not found'))) {
        await _cleanupInstallArtifacts(
          version: version,
          versionDir: versionDir,
          removeCache: true,
        );

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
    }

    await _cleanupInstallArtifacts(
      version: version,
      versionDir: versionDir,
      removeCache: true,
    );

    if (error is AppException) {
      Error.throwWithStackTrace(error, stackTrace);
    }

    logger.debug('Clone error details: $error');
    Error.throwWithStackTrace(
      AppException(
        'Failed to install Flutter SDK: ${version.printFriendlyName}.\n'
        'Run with --verbose for more details.',
      ),
      stackTrace,
    );
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
    final versionDir = _setupCacheDirectories(version);
    final channel = await _resolveChannel(version);
    final repoUrl = _resolveRepositoryUrl(version);
    final echoOutput = !(context.isTest || !logger.isVerbose);

    try {
      final cloneOutcome = await _executeClone(
        version: version,
        versionDir: versionDir,
        repoUrl: repoUrl,
        channel: channel,
        echoOutput: echoOutput,
      );

      // Verify clone produced a valid git repository
      final isGit = await GitDir.isGitDir(versionDir.path);
      if (!isGit) {
        throw AppException(
          'Flutter SDK is not a valid git repository after clone. Please try again.',
        );
      }

      await _validateReference(
        version: version,
        versionDir: versionDir,
        clonedFromMirror: cloneOutcome.clonedFromMirror,
        repoUrl: repoUrl,
        channel: channel,
        echoOutput: echoOutput,
      );

      if (cloneOutcome.result.exitCode != ExitCode.success.code) {
        throw AppException(
          'Could not clone Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
        );
      }
    } catch (error, stackTrace) {
      await _handleCloneError(
        error: error,
        stackTrace: stackTrace,
        version: version,
        versionDir: versionDir,
        repoUrl: repoUrl,
      );
    }
  }
}

class _CloneOutcome {
  final ProcessResult result;
  final bool clonedFromMirror;

  const _CloneOutcome({
    required this.result,
    required this.clonedFromMirror,
  });
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
