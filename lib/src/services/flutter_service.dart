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
import 'cache_service.dart';
import 'git_service.dart';
import 'logger_service.dart';
import 'process_service.dart';
import 'releases_service/releases_client.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterService extends ContextualService {
  FlutterService(super.context);

  Future<ProcessResult> run(
    String cmd,
    List<String> args,
    CacheFlutterVersion version, {
    bool throwOnError = false,
  }) {
    final versionRunner = VersionRunner(context: context, version: version);

    return versionRunner.run(cmd, args, throwOnError: throwOnError);
  }

  Future<ProcessResult> pubGet(
    CacheFlutterVersion version, {
    bool throwOnError = false,
    bool offline = false,
  }) {
    final args = ['pub', 'get', if (offline) '--offline'];

    return run('flutter', args, version, throwOnError: throwOnError);
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
    final versionDir = get<CacheService>().getVersionCacheDir(version.name);

    assert(!version.isCustom, 'Custom version is not supported');

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
        final release =
            await get<FlutterReleaseClient>().getReleaseByVersion(version.name);

        if (release != null) {
          channel = release.channel.name;
        }
      }
    }

    try {
      final result = await runGit(
        [
          'clone',
          '--progress',
          if (!version.isUnknownRef) ...[
            '-c',
            'advice.detachedHead=false',
            '-b',
            channel,
          ],
          if (context.gitCache) ...['--reference', context.gitCachePath],
          context.flutterUrl,
          versionDir.path,
        ],
        echoOutput: !(context.isTest || !logger.isVerbose),
      );

      final gitVersionDir =
          get<CacheService>().getVersionCacheDir(version.name);
      final isGit = await GitDir.isGitDir(gitVersionDir.path);

      if (!isGit) {
        throw AppException(
          'Flutter SDK is not a valid git repository after clone. Please try again.',
        );
      }

      /// If version is not a channel reset to version
      if (!version.isChannel) {
        await get<GitService>().resetHard(
          gitVersionDir.path,
          version.version,
        );
      }

      if (result.exitCode != ExitCode.success.code) {
        throw AppException(
          'Could not clone Flutter SDK: ${cyan.wrap(version.printFriendlyName)}',
        );
      }
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
