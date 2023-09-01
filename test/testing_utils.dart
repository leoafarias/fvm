import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fvm/constants.dart';
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:scope/scope.dart';
import 'package:test/test.dart';

// git clone --mirror https://github.com/flutter/flutter.git ~/gitcaches/flutter.git
// git clone --reference ~/gitcaches/flutter.git https://github.com/flutter/flutter.git
// git remote update

final _defaultTestContext = FVMContext.create(
  'TEST',
  fvmDir: getFvmTestHomeDir(),
  isTest: true,
).copyWith(
  useGitCache: true,
  // Use the existing gitCacheDir
  gitCacheDir: FVMContext.main.gitCacheDir,
);

class TestFvmCommandRunner {
  TestFvmCommandRunner();

  Future<int> run(String command) async {
    final args = command.split(' ');
    final firstArg = args.removeAt(0);
    if (firstArg != 'fvm') throw Exception('Include fvm in command');
    return FvmCommandRunner(context: use(contextKey)).run(args);
  }
}

String release = '2.2.1';
const channel = 'beta';
const gitHash = 'f4c74a6ec3';
String? channelVersion;

Directory getFvmTestHomeDir() {
  return Directory(join(kUserHome, 'fvm-test'));
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
  if (ctx.fvmVersionsDir.existsSync()) {
    final cacheDirList = ctx.fvmVersionsDir.listSync(recursive: true);
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
  Future<void> Function() body, {
  String? id,
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  List<String>? tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  // Create random key if it does not exist

  final scope = Scope()..value(contextKey, _defaultTestContext);

  return test(
    description,
    () => scope.run(body),
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
  dynamic Function() body, {
  String? id,
  Timeout? timeout,
  dynamic skip,
  List<String>? tags,
  Map<String, dynamic>? onPlatform,
  FVMContext? context,
  int? retry,
}) {
  return group(
    description,
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
    () {
      Scope()
        ..value(contextKey, _defaultTestContext.merge(context))
        ..runSync(body);
    },
  );
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

/// Lists repository tags
Future<List<String>> getFlutterTags() async {
  final result = await Process.run(
    'git',
    ['ls-remote', '--tags', '--refs', kFlutterRepo],
  );

  var tags = result.stdout.split('\n') as List<String>;

  var versionsList = <String>[];
  for (var tag in tags) {
    final version = tag.split('refs/tags/');

    if (version.length > 1) {
      versionsList.add(version[1]);
    }
  }

  return versionsList;
}

/// Returns the [name] of a branch or tag for a [version]
Future<String?> getBranch(String version) async {
  final versionDir = Directory(join(ctx.fvmVersionsDir.path, version));
  final result = await Process.run(
    'git',
    ['rev-parse', '--abbrev-ref', 'HEAD'],
    workingDirectory: versionDir.path,
  );
  return result.stdout.trim() as String;
}

/// Returns the [name] of a tag [version]
Future<String?> getTag(String version) async {
  final versionDir = Directory(join(ctx.fvmVersionsDir.path, version));
  final result = await Process.run(
    'git',
    ['describe', '--tags', '--exact-match'],
    workingDirectory: versionDir.path,
  );
  return result.stdout.trim() as String;
}
