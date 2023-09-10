import 'dart:async';
import 'dart:io';

import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:git/git.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import '../../exceptions.dart';
import '../../fvm.dart';
import '../models/flutter_version_model.dart';
import '../utils/commands.dart';

/// Helpers and tools to interact with Flutter sdk
class FlutterTools {
  FlutterTools();

  static FlutterTools get instance => ctx.get<FlutterTools>();

  /// Upgrades a cached channel
  Future<void> runUpgrade(CacheFlutterVersion version) async {
    if (version.isChannel) {
      await runFlutter(version, ['upgrade']);
    } else {
      throw FvmUsageException('Can only upgrade Flutter Channels');
    }
  }

  /// Runs triggers sdk setup/install
  Future<int> runSetup(CacheFlutterVersion version) async {
    return runFlutter(version, ['doctor', '--version']);
  }

  /// Runs pub get
  Future<void> runPubGet(CacheFlutterVersion version) async {
    await runFlutter(
      version,
      ['pub', 'get'],
      showOutput: false,
    );
  }

  /// Clones Flutter SDK from Version Number or Channel
  Future<void> install(FlutterVersion version) async {
    final versionDir = CacheService.instance.getVersionCacheDir(version.name);

    // Check if its git commit
    String? channel;

    if (version.isChannel) {
      channel = version.name;
      // If its not a commit hash
    } else if (version.isRelease) {
      if (version.releaseChannel != null) {
        // Version name forces channel version
        channel = version.releaseChannel;
      } else {
        final release =
            await FlutterReleasesClient.getReleaseFromVersion(version.name);
        channel = release?.channel.name;
      }
    }

    if (ctx.useGitCache) {
      await _updateFlutterRepoCache();
    }

    final versionCloneParams = [
      '-c',
      'advice.detachedHead=false',
      '-b',
      channel ?? version.name,
    ];

    final useMirrorParams = [
      '--reference',
      ctx.gitCacheDir,
    ];

    final cloneArgs = [
      //if its a git hash
      if (!version.isCommit) ...versionCloneParams,
      if (ctx.useGitCache) ...useMirrorParams,
    ];

    try {
      await runGit(
        [
          'clone',
          '--progress',
          ...cloneArgs,
          ctx.flutterRepo,
          versionDir.path,
        ],
        echoOutput: true,
      );
    } on Exception {
      CacheService.instance.remove(version);
      rethrow;
    }

    final gitVersionDir =
        CacheService.instance.getVersionCacheDir(version.name);
    final isGit = await GitDir.isGitDir(gitVersionDir.path);

    if (!isGit) {
      throw FvmError('Not a git directory');
    }

    /// If version is not a channel reset to version
    if (!version.isChannel) {
      try {
        final gitDir = await GitDir.fromExisting(gitVersionDir.path);
        // reset --hard $version
        await gitDir.runCommand(['reset', '--hard', version.version]);
      } on FvmException {
        CacheService.instance.remove(version);
        rethrow;
      }
    }

    return;
  }

  /// Gets the global configuration
  String? whichFlutter() {
    final currentFlutter = whichSync('flutter');
    if (currentFlutter == null) return null;
    return dirname(currentFlutter);
  }

  /// Updates local Flutter repo mirror
  /// Will be used mostly for testing
  Future<void> _updateFlutterRepoCache() async {
    final isGitDir = await GitDir.isGitDir(ctx.gitCacheDir);

    // If cache file does not exists create it
    if (isGitDir) {
      final gitDir = await GitDir.fromExisting(ctx.gitCacheDir);
      await gitDir.runCommand(['remote', 'update'], echoOutput: true);
    } else {
      final gitCacheDir = Directory(ctx.gitCacheDir);
      // Ensure brand new directory
      if (gitCacheDir.existsSync()) {
        gitCacheDir.deleteSync(recursive: true);
      }
      gitCacheDir.createSync(recursive: true);

      await runGit(
        ['clone', '--progress', ctx.flutterRepo, gitCacheDir.path],
        echoOutput: true,
      );
    }
  }
}
