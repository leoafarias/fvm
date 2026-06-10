import 'dart:io';

import 'package:fvm/src/utils/constants.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';

const _kSharedTestCacheDirName = 'fvm_test_cache';
const _kSharedTestWorkspaceDirName = 'workspaces';

String getTempTestDir([String? contextId = '', String path = '']) {
  return join(
    kUserHome,
    _kSharedTestCacheDirName,
    _kSharedTestWorkspaceDirName,
    contextId,
    path,
  );
}

String getTempTestProjectDir([String? contextId = '', String name = '']) {
  return join(getTempTestDir(contextId, 'projects'), name);
}

String getSupportAssetDir(String name) {
  return join(Directory.current.path, 'test', 'support_assets', name);
}

final List<String> directories = [
  getSupportAssetDir('flutter_app'),
  getSupportAssetDir('dart_package'),
  getSupportAssetDir('empty_folder'),
];

Future<void> prepareLocalProjects(String toPath) async {
  final promises = <Future<void>>[];
  for (var directory in directories) {
    final assetDir = Directory(directory);
    final assetDirName = basename(assetDir.path);
    final tmpDir = Directory(join(toPath, assetDirName));

    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }

    await tmpDir.create(recursive: true);

    // Copy assetDir to tmpDir
    promises.add(copyPath(assetDir.path, tmpDir.path));
  }

  await Future.wait(promises);
}

Future<void> setUpContext(
  FvmContext context, [
  bool removeTempDir = true,
]) async {
  final tempPath = getTempTestDir(context.debugLabel);

  final tempDir = Directory(tempPath);
  final projects = Directory(getTempTestProjectDir(context.debugLabel));

  if (projects.existsSync()) {
    projects.deleteSync(recursive: true);
  }

  if (!tempDir.existsSync()) {
    tempDir.createSync(recursive: true);
  } else if (removeTempDir) {
    tempDir.deleteSync(recursive: true);
    tempDir.createSync(recursive: true);
  }

  await prepareLocalProjects(projects.path);
}

void tearDownContext(FvmContext context) {
  final tempPath = getTempTestDir(context.debugLabel);

  final tempDir = Directory(tempPath);

  if (!tempDir.existsSync()) return;

  try {
    tempDir.deleteSync(recursive: true);
  } on FileSystemException {
    // Best-effort cleanup: tests should not fail only because the OS still has
    // a handle open on a file inside the fixture workspace.
  }
}
