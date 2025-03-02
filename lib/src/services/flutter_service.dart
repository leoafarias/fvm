import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart' as io;
import 'package:meta/meta.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../utils/context.dart';
import '../utils/exceptions.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'releases_service/releases_client.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterService extends Contextual {
  @protected
  final CacheService cache;

  @protected
  final FlutterReleasesService flutterReleasesServices;

  FlutterService(
    super.context, {
    required this.cache,
    required this.flutterReleasesServices,
  });

  Future<ProcessResult> runFlutter(
    CacheFlutterVersion version,
    List<String> args,
  ) {
    return run(version, 'flutter', args);
  }

  Future<ProcessResult> runDart(
    CacheFlutterVersion version,
    List<String> args,
  ) {
    return run(version, 'dart', args);
  }

  Future<ProcessResult> run(
    CacheFlutterVersion version,
    String cmd,
    List<String> args,
  ) {
    final versionRunner = VersionRunner(context: context, version: version);

    return versionRunner.run(cmd, args);
  }

  /// Clones Flutter SDK from Version Number or Channel
  Future<void> install(FlutterVersion version) async {
    final versionDir = cache.getVersionCacheDir(version.name);

    final versionCloneParams = [
      '-c',
      'advice.detachedHead=false',
      '-b',
      version.branch,
    ];

    final useMirrorParams = ['--reference', context.gitCachePath];

    final useGitCache = context.gitCache;

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

      final isGit = await GitDir.isGitDir(versionDir.path);

      if (!isGit) {
        throw AppException(
          'Flutter SDK is not a valid git repository after clone. Please try again.',
        );
      }

      if (version is ReleaseVersion) {
        await services.git.resetToReference(versionDir.path, version.release);
      } else if (version is CommitVersion) {
        await services.git.resetToReference(versionDir.path, version.name);
      }

      if (result.exitCode != io.ExitCode.success.code) {
        throw AppException(
          'Could not clone Flutter SDK: ${cyan.wrap(version.friendlyName)}',
        );
      }
    } on Exception {
      cache.remove(version);
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

    _context.logger.detail('Starting to update environment variables...');

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
    return await _context.services.process.run(
      cmd,
      args: args,
      environment: environment,
      throwOnError: throwOnError ?? false,
      echoOutput: echoOutput ?? true,
    );
  }
}
