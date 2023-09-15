import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:path/path.dart';

String getTempTestDir(String contextId, [String path = '']) {
  return join(kUserHome, 'fvm-test', contextId, path);
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
    promises.add(copyDirectory(assetDir, tmpDir));
  }

  await Future.wait(promises);
}

Future<void> copyDirectory(Directory source, Directory target) async {
  await for (var entity in source.list(recursive: false)) {
    if (entity is Directory) {
      var newDir = Directory('${target.path}/${entity.uri.pathSegments.last}');
      await newDir.create(recursive: true);
      await copyDirectory(entity, newDir);
    } else if (entity is File) {
      await entity.copy('${target.path}/${entity.uri.pathSegments.last}');
    }
  }
}

Future<void> setUpContext(FVMContext context) async {
  final tempPath = getTempTestDir(context.id);

  final tempDir = Directory(tempPath);

  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }

  tempDir.createSync(recursive: true);

  await prepareLocalProjects(tempDir.path);
}

void tearDownContext(FVMContext context) {
  final tempPath = getTempTestDir(context.id);

  final tempDir = Directory(tempPath);

  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}
