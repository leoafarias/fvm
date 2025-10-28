import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';
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

  /// Attempts to clone with --reference flag for optimization, falls back to normal clone on failure
  Future<ProcessResult> _cloneWithFallback({
    required String repoUrl,
    required Directory versionDir,
    required FlutterVersion version,
    required String? channel,
  }) async {
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
    ];

    final echoOutput = !(context.isTest || !logger.isVerbose);

    // Try with --reference first if git cache is enabled
    if (context.gitCache) {
      try {
        return await runGit([
          ...args,
          '--reference',
          context.gitCachePath,
          repoUrl,
          versionDir.path,
        ], echoOutput: echoOutput);
      } on ProcessException catch (e) {
        if (isReferenceError(e.toString())) {
          logger.warn(
            'Git clone with --reference failed, falling back to normal clone',
          );
          _cleanupPartialClone(versionDir);
          // Fall through to normal clone
        } else {
          rethrow;
        }
      }
    }

    // Normal clone without --reference
    return await runGit([
      ...args,
      repoUrl,
      versionDir.path,
    ], echoOutput: echoOutput);
  }

  /// Cleans up partial clone state when --reference fails
  void _cleanupPartialClone(Directory versionDir) {
    try {
      if (versionDir.existsSync()) {
        versionDir.deleteSync(recursive: true);
      }
    } catch (_) {
      // Ignore cleanup failures - main operation should continue
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

    try {
      final result = await _cloneWithFallback(
        repoUrl: repoUrl,
        versionDir: versionDir,
        version: version,
        channel: channel,
      );

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
          // First check if this is actually a branch in the forked repo
          final gitDir = await GitDir.fromExisting(gitVersionDir.path);
          final branchResult = await gitDir.runCommand([
            'branch',
            '-r',
            '--list',
            'origin/${version.version}',
          ]);

          final branchOutput = (branchResult.stdout as String).trim();
          final isBranch = branchOutput.isNotEmpty;

          if (isBranch) {
            // If it's a branch, just check it out instead of hard reset
            await gitDir.runCommand(['checkout', version.version]);
            logger.debug('Checked out branch: ${version.version}');
          } else {
            // If it's not a branch, perform the hard reset
            await get<GitService>().resetHard(
              gitVersionDir.path,
              version.version,
            );
          }
        } catch (e, stackTrace) {
          // Handle specific git errors for reference not found
          String errorMessage = e.toString().toLowerCase();

          // Simplify to focus on most common error patterns
          if (errorMessage.contains('unknown revision') ||
              errorMessage.contains('ambiguous argument') ||
              errorMessage.contains('not found')) {
            // Clean up failed installation
            get<CacheService>().remove(version);

            // Provide a clear error message
            if (version.fromFork) {
              Error.throwWithStackTrace(
                AppException(
                  'Reference "${version.version}" was not found in fork "${version.fork}".\n'
                  'Please verify that this version exists in the forked repository.\n'
                  'Repository URL: $repoUrl',
                ),
                stackTrace,
              );
            }
            Error.throwWithStackTrace(
              AppException(
                'Reference "${version.version}" was not found in the Flutter repository.\n'
                'Please check that you have specified a valid version.\n'
                'Repository URL: $repoUrl',
              ),
              stackTrace,
            );
          }

          // If it's not a "reference not found" error, rethrow the original exception
          rethrow;
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

  /// Checks if the error is related to --reference flag failures
  @visibleForTesting
  bool isReferenceError(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();

    const referenceErrorPatterns = [
      'reference repository',
      'reference not found',
      'unable to read reference',
      'bad object',
    ];

    return referenceErrorPatterns.any(lowerMessage.contains) ||
        (lowerMessage.contains('corrupt') &&
            lowerMessage.contains('reference'));
  }
}

class VersionRunner {
  final FvmContext _context;
  final CacheFlutterVersion _version;

  const VersionRunner({
    required FvmContext context,
    required CacheFlutterVersion version,
  }) : _context = context,
       _version = version;

  Map<String, String> _updateEnvironmentVariables(List<String> paths) {
    // Remove any values that are similar
    // within the list of paths.
    paths = paths.toSet().toList();

    final env = _context.environment;

    final logger = _context.get<Logger>();

    logger.debug('Starting to update environment variables...');

    final updatedEnvironment = Map<String, String>.of(env);

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
