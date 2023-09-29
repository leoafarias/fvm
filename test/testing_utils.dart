import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/logger_service.dart';
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

class TestCommandRunner {
  TestCommandRunner();

  Future<int> run(String command) async {
    final args = command.split(' ');
    final firstArg = args.removeAt(0);
    if (firstArg != 'fvm') throw Exception('Include fvm in command');
    final scope = Scope()..value(contextKey, ctx);
    return scope.run(() => FvmCommandRunner().run(args));
  }
}

Future<String> getStdout(String command) async {
  final executable = command.split(' ').first;
  // Executable is on something like ./bin/main.dart

  // Which is the relactive to the Directory.current
  // However the script will be executed from a test directory on ctx.workingDirectory
  // This directory is most likely in the user home folder but could be anywhere
  // So we need to get the relative path from the script to the current directory
  // and then join it to the ctx.workingDirectory
  final scriptPath = join(Directory.current.path, executable);
  final relativePath = relative(scriptPath, from: ctx.workingDirectory);
  final executablePath = join(ctx.workingDirectory, relativePath);

  final arguments = command.split(' ').sublist(1);
  final result = await Process.run(
    executablePath,
    arguments,
    workingDirectory: ctx.workingDirectory,
  );

  if (result.exitCode != 0) {
    throw Exception('Error executing command: ${result.stderr}');
  }

  return result.stdout.toString().trim();
}

const kVersionList = [
  channel,
  'stable',
  'master',
  '3.10.2',
  '2.2.2@beta',
  '2.11.0-0.1.pre',
  '2.0.3',
  release,
  forceRelease,
  gitCommit
];

const release = '2.2.1';
const channel = 'beta';
const gitCommit = 'f4c74a6ec3';
const forceRelease = '2.2.2@beta';

Future<FlutterVersion> getRandomFlutterVersion() async {
  final payload = await FlutterReleases.get();
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
void testGroupWithContext(String description, Future<void> Function() body) {
  // Create random key if it does not exist

  final scope = Scope()..value(contextKey, ctx);

  return test(
    description,
    () => scope.run(body),
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
  // Caches fvm install for faster testing
  bool? cacheFvmInstall,
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
      final config = AppConfig.empty().copyWith(
        cachePath: getTempTestDir(contextId, 'fvm'),
        gitCachePath: FVMContext.main.gitCachePath,
      );
      final testContext = FVMContext.create(
        id: contextId,
        configOverrides: config,
        workingDirectory: getTempTestProjectDir(contextId, 'flutter_app'),
        isTest: true,
      );

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
  final versionDir = Directory(join(ctx.versionsCachePath, version));

  final isGitDir = await GitDir.isGitDir(versionDir.path);

  if (!isGitDir) throw Exception('Not a git directory');

  final gitDir = await GitDir.fromExisting(versionDir.path);

  final result = await gitDir.currentBranch();

  return result.branchName;
}

/// Returns the [name] of a tag [version]
Future<String?> getTag(String version) async {
  final versionDir = Directory(join(ctx.versionsCachePath, version));

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

Future<void> getCommitCount() async {
  final gitDir = await GitDir.fromExisting(ctx.gitCachePath);
  final result = await gitDir.runCommand(
    ['rev-list', '--count', 'HEAD..origin/master'],
    echoOutput: true,
  );
  final commitCount = result.stdout.trim();
  logger.info(commitCount);
}

Future<DateTime> getDateOfLastCommit() async {
  final gitDir = await GitDir.fromExisting(ctx.gitCachePath);
  final result = await gitDir.runCommand(
    ['log', '-1', '--format=%cd', '--date=short'],
  );
  final lastCommitDate = result.stdout.trim();

  return DateTime.parse(lastCommitDate);
}
