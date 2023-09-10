import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/services/context.dart';
import 'package:path/path.dart';

String getFvmTestHomeDir(String path) {
  return join(kUserHome, 'fvm-test', path);
}

String getSupportAssetDir(String name) {
  return join(ctx.workingDirectory, 'test', 'support_assets', name);
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
  final fvmDir = Directory(context.fvmDir);
  if (fvmDir.existsSync()) {
    fvmDir.deleteSync(recursive: true);
  }

  final workingDirectory = Directory(context.workingDirectory);
  if (workingDirectory.existsSync()) {
    workingDirectory.deleteSync(recursive: true);
  }
  workingDirectory.createSync(recursive: true);

  await prepareLocalProjects(getFvmTestHomeDir(join('projects', ctx.name)));
}

void tearDownContext(FVMContext context) {
  final fvmDir = Directory(context.fvmDir);
  final workingDirectory = Directory(context.workingDirectory);
  if (fvmDir.existsSync()) {
    fvmDir.deleteSync(recursive: true);
  }

  if (workingDirectory.existsSync()) {
    workingDirectory.deleteSync(recursive: true);
  }
}
