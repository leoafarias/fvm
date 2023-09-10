import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/services/context.dart';
import 'package:path/path.dart';

Directory getTempTestDir(String contextId, [String path = '']) {
  return Directory(join(kUserHome, 'fvm-test', contextId, path));
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
    final tmpDir = Directory(toPath);

    // Copy assetDir to tmpDir
    promises.add(copyDirectoryContents(assetDir, tmpDir));
  }

  await Future.wait(promises);
}

Future<void> copyFile(File source, String targetPath) async {
  await source.openRead().pipe(File(targetPath).openWrite());
}

Future<void> copyDirectoryContents(
  Directory sourceDir,
  Directory targetDir,
) async {
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final tasks = <Future>[];
  await for (var entity in sourceDir.list()) {
    final targetPath = '${targetDir.path}/${entity.uri.pathSegments.last}';
    if (entity is File) {
      tasks.add(copyFile(entity, targetPath));
    } else if (entity is Directory) {
      tasks.add(copyDirectoryContents(entity, Directory(targetPath)));
    }
  }

  await Future.wait(tasks);
}

Future<void> setUpContext(FVMContext context) async {
  final tempDir = getTempTestDir(context.name);

  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }

  await prepareLocalProjects(tempDir.path);
}

void tearDownContext(FVMContext context) {
  final tempDir = getTempTestDir(context.name);

  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}
