import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/context.dart';
import '../utils/exceptions.dart';
import 'base_service.dart';
import 'logger_service.dart';
import 'process_service.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterService extends ContextualService {
  FlutterService(super.context);

  Future<ProcessResult> runFlutter(
    CacheFlutterVersion version,
    List<String> args, {
    bool throwOnError = false,
  }) {
    return run(version, 'flutter', args, throwOnError: throwOnError);
  }

  Future<ProcessResult> runDart(
    CacheFlutterVersion version,
    List<String> args, {
    bool throwOnError = false,
  }) {
    return run(version, 'dart', args, throwOnError: throwOnError);
  }

  Future<ProcessResult> run(
    CacheFlutterVersion version,
    String cmd,
    List<String> args, {
    bool throwOnError = false,
  }) {
    final versionRunner = VersionRunner(context: context, version: version);

    return versionRunner.run(cmd, args, throwOnError: throwOnError);
  }

  Future<void> install(FlutterVersion version) async {
    final versionDir = services.cache.getVersionCacheDir(version.name);

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
            await services.releases.getReleaseFromVersion(version.name);
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
      if (context.gitCache) ...useMirrorParams,
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

      final gitVersionDir = services.cache.getVersionCacheDir(version.name);
      final isGit = await GitDir.isGitDir(gitVersionDir.path);

      if (!isGit) {
        throw AppException(
          'Flutter SDK is not a valid git repository after clone. Please try again.',
        );
      }

      /// If version is not a channel reset to version
      if (!version.isChannel) {
        await services.git
            .resetToReference(gitVersionDir.path, version.version);
      }

      if (result.exitCode != ExitCode.success.code) {
        throw AppException(
          'Could not clone Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
        );
      }
    } on Exception {
      services.cache.remove(version);
      rethrow;
    }
  }
}

class VersionRunner {
  final FVMContext _context;
  final CacheFlutterVersion _version;

  const VersionRunner({
    required FVMContext context,
    required CacheFlutterVersion version,
  })  : _context = context,
        _version = version;

  Map<String, String> _updateEnvironmentVariables(List<String> paths) {
    // Remove any values that are similar
    // within the list of paths.
    paths = paths.toSet().toList();

    final env = _context.environment;

    final logger = _context.get<Logger>();

    logger.detail('Starting to update environment variables...');

    final updatedEnvironment = Map<String, String>.from(env);

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
  }) async {
    // Update environment
    final environment = _updateEnvironmentVariables(
      [_version.binPath, _version.dartBinPath],
    );

    // Run command
    return await _context.get<ProcessService>().run(
          cmd,
          args: args,
          environment: environment,
          throwOnError: throwOnError ?? false,
          echoOutput: echoOutput ?? true,
        );
  }
}
