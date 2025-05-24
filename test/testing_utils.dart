import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:git/git.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'mocks/mock_git_service.dart';

class TestCommandRunner extends FvmCommandRunner {
  TestCommandRunner(
    super.context,
  );

  ServicesProvider get services => context.get();

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
  final result = await gitDir.runCommand(
    ['rev-list', '--count', 'HEAD..origin/master'],
    echoOutput: true,
  );
  final commitCount = result.stdout.trim();
  print('Commit count: $commitCount');
}

Future<DateTime> getDateOfLastCommit(FvmContext context) async {
  final gitDir = await GitDir.fromExisting(context.gitCachePath);
  final result = await gitDir.runCommand(
    ['log', '-1', '--format=%cd', '--date=short'],
  );
  final lastCommitDate = result.stdout.trim();

  return DateTime.parse(lastCommitDate);
}

const _kTempTestDirPrefix = 'TEST_DIR_';

Directory createTempDir([String prefix = '']) {
  prefix = prefix.isEmpty ? '' : '_$prefix';

  return Directory.systemTemp.createTempSync('$_kTempTestDirPrefix$prefix');
}

File createPubspecYaml(Directory directory,
    {String? name, String? sdkConstraint}) {
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

class TestFactory {
  const TestFactory._();

  static TestCommandRunner commandRunner({FvmContext? context}) {
    return TestCommandRunner(context ?? TestFactory.context());
  }

  static FvmContext context({
    String? debugLabel,
    bool? privilegedAccess,
    Map<Type, Generator>? generators,
    String? workingDirectoryOverride,
  }) {
    debugLabel ??= _generateUuid();

    // Create a configuration for the test context using a temporary directory for cache
    // and the main git cache path from the existing FVMContext.
    final config = AppConfig(
      cachePath: createTempDir().path,
      gitCachePath: _sharedGitCacheDir.path,
      privilegedAccess: privilegedAccess,
      useGitCache: true,
    );

    // Create the test context using the computed contextId, the config overrides,
    // and a temporary directory for the working directory.
    final testContext = FvmContext.create(
      debugLabel: debugLabel,
      configOverrides: config,
      logLevel: Level.verbose,
      workingDirectoryOverride:
          workingDirectoryOverride ?? createTempDir(debugLabel).path,
      isTest: true,
      generatorsOverride: {
        FlutterService: _mockFlutterService,
        GitService: _mockGitService,
        ...?generators,
      },
    );

    return testContext;
  }

  /// Creates a new context with an updated working directory
  static FvmContext recreateContextWithWorkingDir(
      FvmContext existing, String workingDirectory) {
    return FvmContext.create(
      debugLabel: existing.debugLabel,
      configOverrides: existing.config,
      logLevel: existing.logLevel,
      workingDirectoryOverride: workingDirectory,
      isTest: existing.isTest,
      generatorsOverride: {
        FlutterService: _mockFlutterService,
        GitService: _mockGitService,
      },
    );
  }

  static MockFlutterService _mockFlutterService(FvmContext context) {
    return MockFlutterService(
      context,
    );
  }

  static MockGitService _mockGitService(FvmContext context) {
    return MockGitService(context);
  }
}

Future<List<String>> runnerZoned(
    FvmCommandRunner runner, List<String> args) async {
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

/// A mock implementation of a Flutter service that installs the SDK
/// by using a local fixture repository instead of performing a real git clone.
class MockFlutterService extends FlutterService {
  // Track installed versions for testing
  final Map<String, bool> _installedVersions = {};

  // Track simulated failures for testing
  final Map<String, String?> _simulatedFailures = {};

  MockFlutterService(
    super.context,
  ) {
    if (!_sharedTestFvmDir.existsSync()) {
      _sharedTestFvmDir.createSync(recursive: true);
    }

    // Default setup: stable channel is installed
    _preInstallDefaultVersions();
  }

  /// Pre-install default versions that should be available in tests
  void _preInstallDefaultVersions() {
    // Install common versions used in tests
    final versionsToInstall = [
      'stable',
      'beta',
      'dev',
      'master',
      '3.10.0',
      '2.10.0',
      'abcdef1234567890', // Mock Git hash for testing
    ];

    for (final versionName in versionsToInstall) {
      final version = FlutterVersion.parse(versionName);
      _createMockInstallation(version);
      _installedVersions[versionName] = true;
    }
  }

  /// Create a mock installation directory structure for a version
  void _createMockInstallation(FlutterVersion version) {
    final cacheService = get<CacheService>();
    final versionDir = cacheService.getVersionCacheDir(version);

    // Create the version directory
    if (!versionDir.existsSync()) {
      versionDir.createSync(recursive: true);
    }

    // Note: We don't create the version file during installation
    // The version file will be created during setup (when flutter --version is run)
    // This ensures that newly installed versions appear as "not setup" initially

    // Create a minimal .git directory to simulate a git repo
    final gitDir = Directory(path.join(versionDir.path, '.git'));
    if (!gitDir.existsSync()) {
      gitDir.createSync();
    }

    // Create necessary git subdirectories
    final objectsDir = Directory(path.join(gitDir.path, 'objects'));
    final refsDir = Directory(path.join(gitDir.path, 'refs'));
    final headsDir = Directory(path.join(gitDir.path, 'refs', 'heads'));

    objectsDir.createSync();
    refsDir.createSync();
    headsDir.createSync();

    // Create a HEAD file to simulate being on a branch
    final headFile = File(path.join(gitDir.path, 'HEAD'));
    // For channels, set the branch to the channel name
    if (isFlutterChannel(version.name)) {
      headFile.writeAsStringSync('ref: refs/heads/${version.name}\n');
    } else if (version.name.contains('@')) {
      // Handle version@channel syntax
      final parts = version.name.split('@');
      if (parts.length == 2) {
        headFile.writeAsStringSync('ref: refs/heads/${parts[1]}\n');
      } else {
        headFile.writeAsStringSync('ref: refs/heads/stable\n');
      }
    } else if (RegExp(r'^[a-f0-9]{7,40}$').hasMatch(version.name)) {
      // For commit hashes, use master branch
      headFile.writeAsStringSync('ref: refs/heads/master\n');
    } else {
      // For specific versions, default to stable
      headFile.writeAsStringSync('ref: refs/heads/stable\n');
    }

    // Create a config file (required by GitDir.isGitDir)
    final configFile = File(path.join(gitDir.path, 'config'));
    configFile.writeAsStringSync('[core]\n\trepositoryformatversion = 0\n');

    // Create a minimal flutter binary to make it look like a real SDK
    final binDir = Directory(path.join(versionDir.path, 'bin'));
    if (!binDir.existsSync()) {
      binDir.createSync();
    }

    // Create a flutter executable file with proper name and permissions
    final flutterExec = File(path.join(binDir.path, flutterExecFileName));

    // Generate mock Flutter version output in the expected format
    String channelName;
    if (isFlutterChannel(version.name)) {
      channelName = version.name;
    } else {
      channelName = 'stable'; // Default channel for specific versions
    }

    // Mock Dart SDK versions that correspond to Flutter versions
    String dartVersionContent;
    if (isFlutterChannel(version.name)) {
      // Mock Dart versions for channels based on realistic versions
      switch (version.name) {
        case 'stable':
          dartVersionContent = '3.6.0';
          break;
        case 'beta':
          dartVersionContent = '3.7.0-0.1.pre';
          break;
        case 'dev':
          dartVersionContent = '2.19.0';
          break;
        case 'master':
        case 'main':
          dartVersionContent = '3.8.0-0.1.pre';
          break;
        default:
          dartVersionContent = '3.6.0';
      }
    } else {
      // For specific versions, use appropriate Dart versions
      if (version.name.startsWith('3.')) {
        dartVersionContent = '3.6.0'; // Modern Flutter versions use Dart 3.x
      } else if (version.name.startsWith('2.')) {
        dartVersionContent = '2.19.0'; // Flutter 2.x used Dart 2.x
      } else {
        dartVersionContent = '3.6.0'; // Default to modern Dart
      }
    }

    // Generate mock Flutter version content for the output
    String flutterVersionContent;
    if (isFlutterChannel(version.name)) {
      // Mock version numbers for channels based on realistic Flutter versions
      switch (version.name) {
        case 'stable':
          flutterVersionContent = '3.29.3';
          break;
        case 'beta':
          flutterVersionContent = '3.30.0-0.1.pre';
          break;
        case 'dev':
          flutterVersionContent = '2.13.0-0.1.pre';
          break;
        case 'master':
        case 'main':
          flutterVersionContent = '3.31.0-0.1.pre';
          break;
        default:
          flutterVersionContent = '3.29.3';
      }
    } else {
      // For specific versions or commit hashes, use the version name
      flutterVersionContent = version.name;
    }

    final mockFlutterOutput =
        '''Flutter $flutterVersionContent • channel $channelName • https://github.com/flutter/flutter.git
Framework • revision abc123def4 (1 day ago) • 2024-01-01 12:00:00 -0800
Engine • revision 456789abc1
Tools • Dart $dartVersionContent • DevTools 2.28.0''';

    if (Platform.isWindows) {
      // On Windows, create a batch file
      flutterExec.writeAsStringSync('''@echo off
if "%1"=="--version" (
echo $mockFlutterOutput
) else (
echo Mock Flutter command: %*
)''');
    } else {
      // On Unix-like systems, create a shell script
      flutterExec.writeAsStringSync('''#!/bin/bash
if [ "\$1" = "--version" ]; then
echo "$mockFlutterOutput"
else
echo "Mock Flutter command: \$@"
fi''');
      // Make it executable
      Process.runSync('chmod', ['+x', flutterExec.path]);
    }

    // Create Dart SDK directory structure but not the version file yet
    final dartSdkDir =
        Directory(path.join(versionDir.path, 'bin', 'cache', 'dart-sdk'));
    if (!dartSdkDir.existsSync()) {
      dartSdkDir.createSync(recursive: true);
    }

    // Note: We don't create the Dart SDK version file during installation
    // It will be created during setup to simulate real behavior

    // Create a dart executable in the correct location based on Flutter version
    // For modern versions (>1.17.5), dart is in the main bin directory
    // For old versions (<=1.17.5), dart is in bin/cache/dart-sdk/bin
    String dartExecPath;
    if (version.name.startsWith('1.') &&
        (version.name.startsWith('1.0.') ||
            version.name.startsWith('1.1.') ||
            version.name == '1.17.5' ||
            version.name.startsWith('1.17.') &&
                double.tryParse(version.name.substring(5)) != null &&
                double.parse(version.name.substring(5)) <= 5)) {
      // Old path structure: bin/cache/dart-sdk/bin
      final dartBinDir = Directory(path.join(dartSdkDir.path, 'bin'));
      if (!dartBinDir.existsSync()) {
        dartBinDir.createSync();
      }
      dartExecPath = path.join(dartBinDir.path, dartExecFileName);
    } else {
      // Modern path structure: bin (same as Flutter)
      dartExecPath = path.join(binDir.path, dartExecFileName);
    }

    final dartExec = File(dartExecPath);
    final mockDartOutput = 'Dart SDK version: $dartVersionContent';

    if (Platform.isWindows) {
      // On Windows, create a batch file
      dartExec.writeAsStringSync('''@echo off
if "%1"=="--version" (
echo $mockDartOutput
) else (
echo Mock Dart command: %*
)''');
    } else {
      // On Unix-like systems, create a shell script
      dartExec.writeAsStringSync('''#!/bin/bash
if [ "\$1" = "--version" ]; then
echo "$mockDartOutput"
else
echo "Mock Dart command: \$@"
fi''');
      // Make it executable
      Process.runSync('chmod', ['+x', dartExec.path]);
    }
  }

  /// Clear all installed versions - used for testing the no-versions-installed case
  void clearInstalledVersions() {
    _installedVersions.clear();
  }

  /// Check if a specific version is installed
  bool isVersionInstalled(String version) {
    return _installedVersions[version] == true;
  }

  /// Simulate failure of specific operations for testing error scenarios
  void simulateFailure(String operation, {String? reason}) {
    logger.warn('Simulating failure for operation: $operation');
    if (reason != null) {
      logger.warn('Reason: $reason');
    }
    _simulatedFailures[operation] = reason;
  }

  /// Returns all installed versions that we've recorded
  Future<List<CacheFlutterVersion>> getAllVersions() async {
    final List<CacheFlutterVersion> versions = [];

    for (final version in _installedVersions.keys) {
      if (_installedVersions[version] == true) {
        // Create a dummy CacheFlutterVersion for testing
        final tempDir = createTempDir('mock_version_$version');

        // Use the correct constructor from the implementation
        final flutterVersion = FlutterVersion.parse(version);
        versions.add(CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: tempDir.path,
        ));
      }
    }

    return versions;
  }

  /// Installs the Flutter SDK for the given [version].
  ///
  /// This method checks if a fixture repository already exists in the local
  /// project cache (at `.fixtures/flutter`). If it does not exist, it “clones”
  /// the fixture by creating the directory and a marker file. Finally, it copies
  /// the fixture repository into the version directory (configured via CacheService).
  @override
  Future<void> install(
    FlutterVersion version,
  ) async {
    // Check for simulated failures
    final failureKey = 'install:${version.name}';
    if (_simulatedFailures.containsKey(failureKey)) {
      final reason = _simulatedFailures[failureKey];
      throw Exception('Simulated failure for $failureKey: $reason');
    }

    // Create the mock installation directory structure
    _createMockInstallation(version);

    // Mark this version as installed in our tracking map
    _installedVersions[version.name] = true;
    logger.info('Installed mock version: ${version.name}');
  }

  /// Simulates the setup process by creating the version file
  @override
  Future<ProcessResult> setup(CacheFlutterVersion version) async {
    // Create the version file during setup to simulate real behavior
    final versionFile = File(path.join(version.directory, 'version'));

    // Generate the appropriate version content
    String flutterVersionContent;
    if (isFlutterChannel(version.name)) {
      // Mock version numbers for channels based on realistic Flutter versions
      switch (version.name) {
        case 'stable':
          flutterVersionContent = '3.29.3';
          break;
        case 'beta':
          flutterVersionContent = '3.30.0-0.1.pre';
          break;
        case 'dev':
          flutterVersionContent = '2.13.0-0.1.pre';
          break;
        case 'master':
        case 'main':
          flutterVersionContent = '3.31.0-0.1.pre';
          break;
        default:
          flutterVersionContent = '3.29.3';
      }
    } else {
      // For specific versions or commit hashes, use the version name
      flutterVersionContent = version.name;
    }

    versionFile.writeAsStringSync(flutterVersionContent);

    // Also create the Dart SDK version file during setup
    final dartSdkDir =
        Directory(path.join(version.directory, 'bin', 'cache', 'dart-sdk'));
    if (!dartSdkDir.existsSync()) {
      dartSdkDir.createSync(recursive: true);
    }

    final dartVersionFile = File(path.join(dartSdkDir.path, 'version'));

    // Generate appropriate Dart version content
    String dartVersionContent;
    if (isFlutterChannel(version.name)) {
      // Mock Dart versions for channels based on realistic versions
      switch (version.name) {
        case 'stable':
          dartVersionContent = '3.6.0';
          break;
        case 'beta':
          dartVersionContent = '3.7.0-0.1.pre';
          break;
        case 'dev':
          dartVersionContent = '2.19.0';
          break;
        case 'master':
        case 'main':
          dartVersionContent = '3.8.0-0.1.pre';
          break;
        default:
          dartVersionContent = '3.6.0';
      }
    } else {
      // For specific versions, use appropriate Dart versions
      if (version.name.startsWith('3.')) {
        dartVersionContent = '3.6.0'; // Modern Flutter versions use Dart 3.x
      } else if (version.name.startsWith('2.')) {
        dartVersionContent = '2.19.0'; // Flutter 2.x used Dart 2.x
      } else {
        dartVersionContent = '3.6.0'; // Default to modern Dart
      }
    }

    dartVersionFile.writeAsStringSync(dartVersionContent);

    // Return a successful ProcessResult
    return ProcessResult(0, 0, 'Mock setup completed', '');
  }
}

final _sharedTestFvmDir = Directory(p.join(kUserHome, 'fvm_test_cache'));
final _sharedGitCacheDir =
    Directory(p.join(_sharedTestFvmDir.path, 'gitcache'));
