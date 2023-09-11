import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/context.dart';
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
    final assetDirName = basename(assetDir.path);
    final tmpDir = Directory(join(toPath, assetDirName));

    // Copy assetDir to tmpDir
    promises.add(copyDirectory(assetDir, tmpDir));
  }

  await Future.wait(promises);
}

Future<void> copyDirectory(Directory source, Directory target) async {
  if (await target.exists()) {
    await target.delete(recursive: true);
  }

  await target.create(recursive: true);
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
  final tempDir = getTempTestDir(context.name);

  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }

  tempDir.createSync(recursive: true);

  await prepareLocalProjects(tempDir.path);
}

void tearDownContext(FVMContext context) {
  final tempDir = getTempTestDir(context.name);

  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}
