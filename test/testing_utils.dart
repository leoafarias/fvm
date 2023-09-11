import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:git/git.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:scope/scope.dart';
import 'package:test/test.dart';

import 'testing_helpers/prepare_test_environment.dart';

// git clone --mirror https://github.com/flutter/flutter.git ~/gitcaches/flutter.git
// git clone --reference ~/gitcaches/flutter.git https://github.com/flutter/flutter.git
// git remote update

class TestFvmCommandRunner {
  TestFvmCommandRunner();

  Future<int> run(String command) async {
    final args = command.split(' ');
    final firstArg = args.removeAt(0);
    if (firstArg != 'fvm') throw Exception('Include fvm in command');
    final scope = Scope()..value(contextKey, ctx);
    return scope.run(() => FvmCommandRunner().run(args));
  }
}

const kVersionList = [
  'beta',
  'master',
  '3.10.2',
  '2.2.2@beta',
  '2.11.0-0.1.pre',
  '2.0.3',
  'f4c74a6ec3'
];

const release = '2.2.1';
const channel = 'beta';
const gitCommit = 'f4c74a6ec3';

Future<FlutterVersion> getRandomFlutterVersion() async {
  final payload = await FlutterReleasesClient.get();
  final release = payload.releases[Random().nextInt(payload.releases.length)];
  return FlutterVersion.parse(release.version);
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

  final scope = Scope()..value(contextKey, ctx);

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
  // lowecase description, and replace spaces with underscores
  final contextId = description
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-zA-Z0-9_ ]'), '')
      .replaceAll(' ', '_');

  return group(
    description,
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
    () {
      final testContext = FVMContext.create(
        contextId,
        fvmDir: getTempTestDir(contextId, 'fvm').path,
        workingDirectory: getTempTestDir(contextId, 'flutter_app').path,
        isTest: true,
        gitCacheDir: FVMContext.main.gitCacheDir,
      ).merge(context);

      Scope()
        ..value(contextKey, testContext)
        ..runSync(() {
          setUpAll(() => setUpContext(testContext));
          tearDownAll(() => tearDownContext(testContext));
          body();
        });
    },
  );
}

/// Returns the [name] of a branch or tag for a [version]
Future<String?> getBranch(String version) async {
  final versionDir = Directory(join(ctx.fvmVersionsDir, version));

  final isGitDir = await GitDir.isGitDir(versionDir.path);

  if (!isGitDir) throw Exception('Not a git directory');

  final gitDir = await GitDir.fromExisting(versionDir.path);

  final result = await gitDir.currentBranch();

  return result.branchName;
}

/// Returns the [name] of a tag [version]
Future<String?> getTag(String version) async {
  final versionDir = Directory(join(ctx.fvmVersionsDir, version));

  final isGitDir = await GitDir.isGitDir(versionDir.path);

  if (!isGitDir) throw Exception('Not a git directory');

  final gitDir = await GitDir.fromExisting(versionDir.path);

  try {
    final pr = await gitDir.runCommand(['describe', '--tags', '--exact-match']);
    return (pr.stdout as String).trim();
  } catch (e) {
    return null;
  }
}

/// update sdk version in a cache version
void forceUpdateFlutterSdkVersionFile(
  CacheFlutterVersion version,
  String sdkVersion,
) {
  final sdkVersionFile = File(join(version.directory, 'version'));
  sdkVersionFile.writeAsStringSync(sdkVersion);
}
