import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:git/git.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class TestCommandRunner extends FvmCommandRunner {
  TestCommandRunner(super.context);

  @override
  Future<int> run(Iterable<String> args) async {
    final firstArg = args.first;
    if (firstArg != 'fvm') throw Exception('Include fvm in command');

    final updatedArgs = args.skip(1).toList();

    assert(
      context.isTest == true,
      'Controller must be created with isTest: true',
    );

    return super.run(updatedArgs);
  }

  Future<int> runOrThrow(Iterable<String> args) async {
    final updatedArgs = args.skip(1).toList();
    await runCommand(parse(updatedArgs));
    return ExitCode.success.code;
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

Future<void> getCommitCount(FvmContext context) async {
  final gitDir = await GitDir.fromExisting(context.gitCachePath);
  final result = await gitDir.runCommand([
    'rev-list',
    '--count',
    'HEAD..origin/master',
  ], echoOutput: true);
  final commitCount = result.stdout.trim();
  print('Commit count: $commitCount');
}

Future<DateTime> getDateOfLastCommit(FvmContext context) async {
  final gitDir = await GitDir.fromExisting(context.gitCachePath);
  final result = await gitDir.runCommand([
    'log',
    '-1',
    '--format=%cd',
    '--date=short',
  ]);
  final lastCommitDate = result.stdout.trim();

  return DateTime.parse(lastCommitDate);
}

const _kTempTestDirPrefix = 'TEST_DIR_';

Directory createTempDir([String prefix = '']) {
  prefix = prefix.isEmpty ? '' : '_$prefix';

  return Directory.systemTemp.createTempSync('$_kTempTestDirPrefix$prefix');
}

File createPubspecYaml(
  Directory directory, {
  String? name,
  String? sdkConstraint,
}) {
  name ??= _generateUuid();

  // environment:
  //  sdk: ">=2.17.0 <4.0.0"

  final file = File(p.join(directory.path, 'pubspec.yaml'));

  final content = StringBuffer();
  content.writeln('name: $name');
  content.writeln('');

  if (sdkConstraint != null) {
    content.writeln('environment:');
    content.writeln(' sdk: "$sdkConstraint"');
  }

  file.writeAsStringSync(content.toString());
  return file;
}

File createProjectConfig(ProjectConfig config, Directory directory) {
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
        'a Project with config at "${_replaceTempDirectory(expectedConfigPath!)}"',
      );
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
        'has config at "${_replaceTempDirectory(item.configPath)}" instead of "${_replaceTempDirectory(matchState['expected'] as String)}"',
      );
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

class TestFactory {
  const TestFactory._();

  static TestCommandRunner commandRunner({FvmContext? context}) {
    return TestCommandRunner(context ?? TestFactory.context());
  }

  static FvmContext context({
    String? debugLabel,
    bool? privilegedAccess,
    Map<Type, Generator>? generators,
    bool? skipInput,
    Map<String, String>? environmentOverrides,
  }) {
    debugLabel ??= _generateUuid();

    // Read global config to preserve forks
    final globalConfig = LocalAppConfig.read();

    // Create a configuration for the test context using a temporary directory for cache
    // and the main git cache path from the existing FVMContext.
    // Always include forks from global config to ensure they're available in tests
    final config = AppConfig(
      cachePath: createTempDir().path,
      gitCachePath: _sharedGitCacheDir.path,
      privilegedAccess: privilegedAccess,
      useGitCache: true,
      forks: globalConfig.forks, // Preserve global forks
    );

    // Create the test context using the computed contextId, the config overrides,
    // and a temporary directory for the working directory.
    final testContext = FvmContext.create(
      debugLabel: debugLabel,
      configOverrides: config,
      logLevel: Level.verbose,
      workingDirectoryOverride: createTempDir(debugLabel).path,
      isTest: true,
      skipInput: skipInput ??
          false, // Allow overriding skipInput for testing user input
      environmentOverrides: environmentOverrides,
      generatorsOverride: {FlutterService: _mockFlutterService, ...?generators},
    );

    return testContext;
  }

  static MockFlutterService _mockFlutterService(FvmContext context) {
    return MockFlutterService(context);
  }
}

Future<List<String>> runnerZoned(
  FvmCommandRunner runner,
  List<String> args,
) async {
  final printed = <String>[];
  await runZoned(
    () async {
      await runner.run(args);
    },
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, String message) {
        printed.add(message);
      },
    ),
  );
  return printed;
}

/// Create a matcher to check if list of strings is a valid json
class _IsExpectedJson extends Matcher {
  final String expected;

  _IsExpectedJson(this.expected);

  @override
  bool matches(item, Map matchState) {
    try {
      String jsonString;
      if (item is List<String>) {
        jsonString = item.join();
      } else {
        jsonString = item;
      }
      final decoded = jsonDecode(jsonString);

      final expectedDecoded = jsonDecode(expected);
      expect(decoded, equals(expectedDecoded));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Description describe(Description description) {
    return description.add(expected);
  }
}

Matcher isExpectedJson(String expected) {
  return _IsExpectedJson(expected);
}

/// A simple test helper that tracks temporary directories for cleanup.
/// Following KISS principle - just what we need, nothing more.
class TempDirectoryTracker {
  final _dirs = <Directory>[];

  /// Creates a temporary directory and tracks it for cleanup.
  Directory create() {
    final dir = createTempDir();
    _dirs.add(dir);
    return dir;
  }

  /// Cleans up all tracked directories.
  void cleanUp() {
    for (final dir in _dirs) {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
    _dirs.clear();
  }
}

/// A mock implementation of a Flutter service that installs the SDK
/// by using a local fixture repository instead of performing a real git clone.
class MockFlutterService extends FlutterService {
  bool? lastUseArchive;
  FlutterVersion? lastInstallVersion;
  Directory? lastInstallDirectory;

  MockFlutterService(super.context) {
    if (!_sharedTestFvmDir.existsSync()) {
      _sharedTestFvmDir.createSync(recursive: true);
    }
  }

  /// Installs the Flutter SDK for the given [version].
  ///
  /// This method checks if a fixture repository already exists in the local
  /// project cache (at `.fixtures/flutter`). If it does not exist, it “clones”
  /// the fixture by creating the directory and a marker file. Finally, it copies
  /// the fixture repository into the version directory (configured via CacheService).
  @override
  Future<void> install(
    FlutterVersion version, {
    bool useArchive = false,
  }) async {
    lastUseArchive = useArchive;
    lastInstallVersion = version;

    if (useArchive) {
      final cacheService = get<CacheService>();
      final versionDir = cacheService.getVersionCacheDir(version);

      lastInstallDirectory = Directory(versionDir.path);

      if (versionDir.existsSync()) {
        versionDir.deleteSync(recursive: true);
      }

      versionDir.createSync(recursive: true);
      Directory(p.join(versionDir.path, 'bin')).createSync(recursive: true);

      final flutterExec = p.join(versionDir.path, 'bin', flutterExecFileName);

      if (Platform.isWindows) {
        File(flutterExec).writeAsStringSync('@echo off\necho Mock Flutter\n');
      } else {
        File(flutterExec).writeAsStringSync('#!/bin/sh\necho Mock Flutter\n');
        Process.runSync('chmod', ['+x', flutterExec]);
      }

      File(p.join(versionDir.path, 'version'))
          .writeAsStringSync(version.version);

      return;
    }

    try {
      await super.install(version, useArchive: useArchive);
      final cacheService = get<CacheService>();
      lastInstallDirectory = cacheService.getVersionCacheDir(version);
    } finally {}
  }
}

final _sharedTestFvmDir = Directory(p.join(kUserHome, 'fvm_test_cache'));
final _sharedGitCacheDir = Directory(
  p.join(_sharedTestFvmDir.path, 'gitcache'),
);
