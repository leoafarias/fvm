import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:git/git.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:scope/scope.dart';
import 'package:test/test.dart';

import 'testing_helpers/prepare_test_environment.dart';

// git clone --mirror https://github.com/flutter/flutter.git ~/gitcaches/flutter.git
// git clone --reference ~/gitcaches/flutter.git https://github.com/flutter/flutter.git
// git remote update

class TestCommandRunner {
  TestCommandRunner([FvmController? controller])
      : _controller = controller ?? _buildTestController();

  final FvmController _controller;

  FvmController get controller => _controller;

  static FvmController _buildTestController() {
    return FvmController(FVMContext.create(
      isTest: true,
      workingDirectoryOverride: createTempDir().path,
    ));
  }

  Future<int> run(String command) async {
    final args = command.split(' ');
    final firstArg = args.removeAt(0);
    if (firstArg != 'fvm') throw Exception('Include fvm in command');

    assert(_controller.context.isTest == true,
        'Controller must be created with isTest: true');

    return FvmCommandRunner(_controller).run(args);
  }
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

  final scope = Scope();

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
        workingDirectoryOverride:
            getTempTestProjectDir(contextId, 'flutter_app'),
        isTest: true,
      );

      Scope().runSync(() {
        setUpAll(() => setUpContext(testContext));
        tearDownAll(() => tearDownContext(testContext));
        body();
      });
    },
  );
}

final ctx = FVMContext.create(isTest: true);
final controller = FvmController(ctx);

/// Returns the [name] of a branch or tag for a [version]
Future<String?> getBranch(String version) async {
  final versionDir = Directory(p.join(ctx.versionsCachePath, version));

  final isGitDir = await GitDir.isGitDir(versionDir.path);

  if (!isGitDir) throw Exception('Not a git directory');

  final gitDir = await GitDir.fromExisting(versionDir.path);

  final result = await gitDir.currentBranch();

  return result.branchName;
}

/// Returns the [name] of a tag [version]
Future<String?> getTag(String version) async {
  final versionDir = Directory(p.join(ctx.versionsCachePath, version));

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
  final sdkVersionFile = File(p.join(version.directory, 'version'));
  sdkVersionFile.writeAsStringSync(sdkVersion);
}

Future<void> getCommitCount() async {
  final gitDir = await GitDir.fromExisting(ctx.gitCachePath);
  final result = await gitDir.runCommand(
    ['rev-list', '--count', 'HEAD..origin/master'],
    echoOutput: true,
  );
  final commitCount = result.stdout.trim();
  controller.logger.info(commitCount);
}

Future<DateTime> getDateOfLastCommit() async {
  final gitDir = await GitDir.fromExisting(ctx.gitCachePath);
  final result = await gitDir.runCommand(
    ['log', '-1', '--format=%cd', '--date=short'],
  );
  final lastCommitDate = result.stdout.trim();

  return DateTime.parse(lastCommitDate);
}

const _kTempTestDirPrefix = 'FVM_TEST_DIR';

Directory createTempDir([String prefix = '']) {
  prefix = prefix.isEmpty ? '' : '_$prefix';
  return Directory.systemTemp.createTempSync('$_kTempTestDirPrefix$prefix');
}

File createPubspecYaml(Directory directory, {String? projectName}) {
  projectName ??= _generateUuid();
  final file = File(p.join(directory.path, 'pubspec.yaml'));
  file.writeAsStringSync('name: $projectName');
  return file;
}

File createFvmConfig(ProjectConfig config, Directory directory) {
  final file = File(p.join(directory.path, '.fvmrc'));
  file.writeAsStringSync(config.toJson());
  return file;
}

/// Generate a random uuid without any dependencies
String _generateUuid() {
  final random = Random();
  const hexDigits = '0123456789abcdef';
  final uuid = List.filled(36, '', growable: false);

  // Generate random hex digits
  for (var i = 0; i < 36; i++) {
    if (i == 8 || i == 13 || i == 18 || i == 23) {
      uuid[i] = '-';
    } else if (i == 14) {
      // Version 4 UUID has '4' as the version number
      uuid[i] = '4';
    } else if (i == 19) {
      // UUID variant (8, 9, a, or b)
      uuid[i] = hexDigits[(random.nextInt(4) + 8)];
    } else {
      uuid[i] = hexDigits[random.nextInt(16)];
    }
  }

  return uuid.join();
}

String _replaceTempDirectory(String path) {
  return path.substring(
    path.indexOf(_kTempTestDirPrefix) + _kTempTestDirPrefix.length,
  );
}

/// Custom matcher to check that a Project has a configuration.
Matcher isProjectMatcher({
  Directory? expectedDirectory,
  bool hasConfig = true,
}) =>
    _ProjectHasConfigMatcher(
      expectedDirectory: expectedDirectory,
      hasConfig: hasConfig,
    );

class _ProjectHasConfigMatcher extends Matcher {
  final Directory? _expectedDirectory;

  final bool _hasConfig;
  _ProjectHasConfigMatcher({
    Directory? expectedDirectory,
    required bool hasConfig,
  })  : _expectedDirectory = expectedDirectory,
        _hasConfig = hasConfig;

  String? get expectedConfigPath => p.join(_expectedDirectory!.path, '.fvmrc');

  @override
  bool matches(item, Map matchState) {
    if (item is! Project) return false;
    if (!item.hasConfig && _hasConfig == true) return false;
    if (item.hasConfig && _hasConfig == false) return false;

    if (expectedConfigPath != null) {
      if (item.configPath != expectedConfigPath) {
        matchState['expected'] = expectedConfigPath;
        matchState['found'] = item.configPath;
        return false;
      }
    }
    if (_hasConfig == false) {
      if (File(item.configPath).existsSync()) {
        matchState['expected'] = 'no config file';
        matchState['found'] = 'has config file';
        return false;
      }
    }
    if (_hasConfig == true) {
      if (!File(item.configPath).existsSync()) {
        matchState['expected'] = 'has config file';
        matchState['found'] = 'no config file';
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) {
    if (expectedConfigPath != null) {
      return description.add(
          'a Project with config at "${_replaceTempDirectory(expectedConfigPath!)}"');
    }
    return description.add('a Project with a valid config');
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! Project) {
      return mismatchDescription.add('is not a Project');
    }
    if (!item.hasConfig) {
      return mismatchDescription.add('does not have a config');
    }
    if (expectedConfigPath != null && item.configPath != expectedConfigPath) {
      return mismatchDescription.add(
          'has config at "${_replaceTempDirectory(item.configPath)}" instead of "${_replaceTempDirectory(matchState['expected'] as String)}"');
    }
    final configFileExists = File(item.configPath).existsSync();
    if (_hasConfig == true && !configFileExists) {
      return mismatchDescription.add('config file does not exist');
    }
    if (_hasConfig == false && configFileExists) {
      return mismatchDescription.add('config file exists');
    }

    return mismatchDescription;
  }
}

FVMContext createTestContext(
    {String? name, AppConfig? appConfig, List<String>? args}) {
  name ??= _generateUuid();

  // Create a configuration for the test context using a temporary directory for cache
  // and the main git cache path from the existing FVMContext.
  final config = AppConfig.empty().copyWith(
    cachePath: createTempDir().path,
    gitCachePath: FVMContext.main.gitCachePath,
  );

  // Create the test context using the computed contextId, the config overrides,
  // and a temporary directory for the working directory.
  final testContext = FVMContext.create(
    id: name,
    configOverrides: config,
    workingDirectoryOverride: createTempDir(name).path,
    isTest: true,
  );

  // Optionally, you can also add the context to a scope if needed:
  // Scope().value(contextKey, testContext);

  return testContext;
}
