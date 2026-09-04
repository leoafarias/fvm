import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/git_service.dart';

/// No-op git mirror operations for fast command/workflow tests.
class FakeGitService extends GitService {
  FakeGitService(super.context);

  int ensureBareCacheCalls = 0;
  int updateLocalMirrorCalls = 0;
  int removeLocalMirrorCalls = 0;

  Exception? ensureBareCacheException;
  Exception? updateLocalMirrorException;

  @override
  Future<void> ensureBareCacheIfPresent() async {
    ensureBareCacheCalls++;
    if (ensureBareCacheException != null) throw ensureBareCacheException!;
  }

  @override
  Future<void> updateLocalMirror() async {
    updateLocalMirrorCalls++;
    if (updateLocalMirrorException != null) throw updateLocalMirrorException!;
  }

  @override
  Future<bool> removeLocalMirror({
    bool requireSuccess = false,
    void Function(FileSystemException error)? onFinalError,
  }) async {
    removeLocalMirrorCalls++;

    return true;
  }

  @override
  Future<String?> getBranch(String version) async {
    final flutterVersion = FlutterVersion.parse(version);

    if (flutterVersion.isChannel) return flutterVersion.name;
    if (flutterVersion.releaseChannel != null) {
      return flutterVersion.releaseChannel!.name;
    }
    if (flutterVersion.isRelease) {
      final release = await context
          .get<FlutterReleaseClient>()
          .getReleaseByVersion(flutterVersion.version);

      return release?.channel.name ?? 'master';
    }

    return 'master';
  }

  @override
  Future<String?> getTag(String version) async {
    final flutterVersion = FlutterVersion.parse(version);

    if (flutterVersion.isRelease) return flutterVersion.version;

    return null;
  }
}
