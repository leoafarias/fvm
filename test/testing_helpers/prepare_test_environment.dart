import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';

String getTempTestDir([String? contextId = '', String path = '']) {
  return join(kUserHome, 'fvm-test', contextId, path);
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
  FVMContext context, [
  bool removeTempDir = true,
]) async {
  final tempPath = getTempTestDir(context.id);

  final tempDir = Directory(tempPath);
  final projects = Directory(getTempTestProjectDir(context.id));

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

void tearDownContext(FVMContext context) {
  // final tempPath = getTempTestDir(context.id);

  // final tempDir = Directory(tempPath);

  // if (tempDir.existsSync()) {
  //   try {
  //     tempDir.deleteSync(recursive: true);
  //   } on FileSystemException catch (e) {
  //     // just log the erorr, as it can fail due to open files
  //     logger.err(e.message);
  //   }
  // }
}
