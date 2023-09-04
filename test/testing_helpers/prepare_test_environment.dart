import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/services/context.dart';
import 'package:path/path.dart';

Directory getFvmTestHomeDir(String path) {
  return Directory(join(kUserHome, 'fvm-test', path));
}

Directory getSupportAssetDir(String name) {
  return Directory(
    join(kWorkingDirectory.path, 'test', 'support_assets', name),
  );
}

Directory getTempTestDirectory(String path1, [String? path2, String? path3]) {
  return Directory(join(kWorkingDirectory.path, 'test', '.tmp', path1, path2));
}

final List<Map<String, String?>> directories = [
  {
    'tmp': getTempTestDirectory('flutter_app').path,
    'asset': getSupportAssetDir('flutter_app').path,
  },
  {
    'tmp': getTempTestDirectory('dart_package').path,
    'asset': getSupportAssetDir('dart_package').path,
  },
  {
    'tmp': getTempTestDirectory('empty_folder').path,
    'asset': getSupportAssetDir('empty_folder').path,
  },
];

Future<void> prepareLocalProjects() async {
  final promises = <Future<void>>[];
  for (var directory in directories) {
    final assetDir = Directory(directory['asset']!);
    final tmpDir = Directory(directory['tmp']!);

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

void setUpContext(FVMContext context) {
  if (context.fvmDir.existsSync()) {
    context.fvmDir.deleteSync(recursive: true);
  }
}

void tearDownContext(FVMContext context) {
  if (context.fvmDir.existsSync()) {
    context.fvmDir.deleteSync(recursive: true);
  }
}
