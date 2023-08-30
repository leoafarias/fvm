import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fvm/constants.dart';
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/services/git_tools.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

// git clone --mirror https://github.com/flutter/flutter.git ~/gitcaches/flutter.git
// git clone --reference ~/gitcaches/flutter.git https://github.com/flutter/flutter.git
// git remote update

String release = '2.2.1';
const channel = 'beta';
const gitHash = 'f4c74a6ec3';
String? channelVersion;

Directory getFvmTestHomeDir(String key) {
  return Directory(join(kUserHome, 'fvmTest', key));
}

Directory getSupportAssetDir(String name) {
  return Directory(
    join(kWorkingDirectory.path, 'test', 'support_assets', name),
  );
}

Directory getTempTestDirectory(String path1, [String? path2, String? path3]) {
  return Directory(join(kWorkingDirectory.path, 'test', '.tmp', path1, path2));
}

final kFlutterAppDir = getTempTestDirectory('apps', 'flutter_app');
final kDartPackageDir = getTempTestDirectory('apps', 'dart_app');
final kEmptyDir = getTempTestDirectory('apps', 'empty_flutter_app');
final kSamplePubspecDir = getTempTestDirectory('pubspecs');

final List<Map<String, String?>> directories = [
  {
    'path': kFlutterAppDir.path,
    'pubspec': 'pubspec_flutter.yaml',
  },
  {
    'path': kDartPackageDir.path,
    'pubspec': 'pubspec_dart.yaml',
  },
  {
    'path': kEmptyDir.path,
    'pubspec': null,
  },
];

void prepareLocalProjects() {
  for (var directory in directories) {
    final dir = Directory(directory['path']!);
    final pubspecFile = directory['pubspec'];

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      if (pubspecFile != null) {
        final pubspec = File(join(dir.path, 'pubspec.yaml'));
        final pubspecContent =
            File(join(kSamplePubspecDir.path, pubspecFile)).readAsStringSync();
        pubspec.writeAsStringSync(pubspecContent);
      }
    }
  }
}

void cleanupLocalProjects() {
  // Remove fvm config from test projects
  final appsDir = getSupportAssetDir('apps');
  appsDir.deleteSync(recursive: true);
}

Future<ValidVersion> getRandomFlutterVersion() async {
  final payload = await fetchFlutterReleases();
  final release = payload.releases[Random().nextInt(payload.releases.length)];
  return ValidVersion(release.version);
}

void cleanup() {
  // Remove all versions
  if (ctx.cacheDir.existsSync()) {
    final cacheDirList = ctx.cacheDir.listSync(recursive: true);
    for (var dir in cacheDirList) {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
  }
}

@isTest
void testWithContext(
  String description,
  void Function() body, {
  String? id,
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  List<String>? tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  // Create random key if it does not exist
  final uniqueId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  return test(
    description,
    () async {
      return ctx.run(
        name: uniqueId,
        fvmHomeDir: getFvmTestHomeDir(uniqueId),
        body: body,
        isTest: true,
      );
    },
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
    testOn: testOn,
  );
}

@isTestGroup
void groupWithContext(
  String description,
  void Function() body, {
  FutureOr<void> Function()? setUpAllFn,
  FutureOr<void> Function()? tearDownFn,
  String? id,
  Timeout? timeout,
  dynamic skip,
  List<String>? tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  final uniqueId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  return group(
    description,
    () {
      return ctx.run(
        name: uniqueId,
        fvmHomeDir: getFvmTestHomeDir(uniqueId),
        isTest: true,
        body: () {
          setUpAll(() async {
            await groupSetUp();
            await setUpAllFn?.call();
          });
          tearDownAll(() async {
            await groupTearDown();
            await tearDownFn?.call();
          });
          body();
        },
      );
    },
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
  );
}

Future<void> groupTearDown() async {
  if (ctx.fvmHome.existsSync()) {
    ctx.fvmHome.deleteSync(recursive: true);
  }
}

Future<void> groupSetUp() async {
  await GitTools.updateFlutterRepoMirror();

  // final defaultGitCache = FVMContext.root.gitCacheDir;

  // // TODO: Improve this to avoid copying
  // await copyDirectoryContents(defaultGitCache, ctx.gitCacheDir);

  if (!ctx.fvmHome.existsSync()) {
    ctx.fvmHome.createSync(recursive: true);
  }
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
