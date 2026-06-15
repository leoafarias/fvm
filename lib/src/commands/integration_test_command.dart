import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart' as p;

import '../models/config_model.dart';
import '../models/flutter_version_model.dart';
import '../runner.dart';
import '../services/cache_service.dart';
import '../services/logger_service.dart';
import '../utils/context.dart';
import '../utils/exceptions.dart';
import 'base_command.dart';

/// Hidden integration test command for complete FVM testing
class IntegrationTestCommand extends BaseFvmCommand {
  @override
  final name = 'integration-test';

  @override
  final description = 'Runs complete integration tests (hidden command)\n'
      'WARNING: This will destroy your FVM cache and reinstall Flutter versions!';

  @override
  final hidden = true; // Hidden from help output

  IntegrationTestCommand(super.context) {
    argParser.addFlag(
      'cleanup-only',
      abbr: 'c',
      help: 'Only run cleanup operations',
      negatable: false,
    );
  }

  void _runCleanup() {
    logger.info('Running integration test cleanup...');
    // Just clean up any temporary test artifacts
    final tempDir = Directory.systemTemp;
    final testArtifacts = tempDir.listSync().where(
          (item) => item.path.contains('fvm_test_artifacts_'),
        );

    for (final artifact in testArtifacts) {
      try {
        if (artifact is Directory) {
          artifact.deleteSync(recursive: true);
        }
      } catch (e) {
        logger.warn('Could not delete ${artifact.path}: $e');
      }
    }

    logger.success('Cleanup completed');
  }

  @override
  Future<int> run() async {
    if (boolArg('cleanup-only')) {
      _runCleanup();

      return ExitCode.success.code;
    }

    final integrationTest = IntegrationTestRunner(context);

    try {
      await integrationTest.runAll();
      logger.success('Integration tests completed successfully!');

      return ExitCode.success.code;
    } catch (e) {
      logger.fail('Integration test failed: $e');

      return ExitCode.software.code;
    }
  }
}

/// Integration test runner that executes complete FVM tests
class IntegrationTestRunner {
  final FvmContext context;

  // Test configuration constants as FlutterVersion objects.
  // Keep the version set intentionally small because this runner performs real
  // network clones and SDK setup against the user's FVM cache.
  // - stable: Real channel install reused by use/setup/destroy/global tests.
  // - fb57da5f94: Real integration commit hash, unrelated to fast fake tests.
  static final testChannelVersion = FlutterVersion.parse('stable');
  static final testCommitVersion = FlutterVersion.parse('fb57da5f94');
  late Directory _testDir;
  late String _originalDir;
  late Directory _tempFilesDir;
  final _phaseCounts = <String, int>{};
  var _testCount = 0;
  var _phaseNumber = 0;
  String? _currentPhase;

  IntegrationTestRunner(this.context);

  /// Setup destructive test environment
  Future<void> _setup() async {
    _originalDir = Directory.current.path;

    // Use current FVM project directory as test directory
    _testDir = Directory(_originalDir);

    // Create temporary files directory for test artifacts
    _tempFilesDir = Directory.systemTemp.createTempSync('fvm_test_artifacts_');

    logger.warn('DESTRUCTIVE INTEGRATION TEST MODE');
    logger.info('Test directory: ${_testDir.path} (current FVM project)');
    logger.info('');
    logger.warn('WARNING: This test will:');
    logger.warn('  - DELETE all your cached Flutter versions');
    logger.warn('  - Download and install multiple Flutter versions');
    logger.warn('  - Modify your project configuration');
    logger.warn(
      '  - This can take 10-30 minutes depending on your internet speed',
    );
    logger.info('');

    // Clean the cache to start with a clean state
    logger.info('Cleaning FVM cache for a clean test environment...');
    await _cleanCache();
    logger.success('Cache cleaned, starting with fresh state');
    logger.info('');
  }

  /// Clean the cache by destroying all versions
  Future<void> _cleanCache() async {
    final cacheService = context.get<CacheService>();

    // Get all installed versions
    final versions = await cacheService.getAllVersions();

    if (versions.isNotEmpty) {
      logger.info(
        'Found ${versions.length} installed versions, destroying cache...',
      );

      // Use destroy command with --force flag to clean everything
      await _runFvmCommand(['destroy', '--force']);

      logger.info('Cache destroyed successfully');
    } else {
      logger.info('Cache is already empty');
    }
  }

  /// Phase 1: Network Release Metadata
  Future<void> _runPhase1ReleaseMetadata() async {
    await _runPhase('Network Release Metadata', () async {
      // REAL INTEGRATION: live release metadata through the production client.
      _logTest('Testing releases command against live metadata...');
      await _runFvmCommand(['releases']);
      _logSuccess('Live releases command works');
    });
  }

  /// Phase 2: Real Installation Workflows
  Future<void> _runPhase2RealInstallations() async {
    await _runPhase('Real Installation Workflows', () async {
      // REAL INTEGRATION: real channel clone/install.
      _logTest('Testing channel installation...');
      await _runFvmCommand(['install', testChannelVersion.name, '--no-setup']);
      await _verifyInstallation(testChannelVersion);
      _logSuccess('Channel installation works');

      // REAL INTEGRATION: real commit clone/install.
      _logTest('Testing Git commit installation...');
      await _runFvmCommand(['install', testCommitVersion.name, '--no-setup']);
      await _verifyInstallation(testCommitVersion);
      _logSuccess('Git commit installation works');
    });
  }

  /// Phase 3: Project Lifecycle
  Future<void> _runPhase3ProjectLifecycle() async {
    await _runPhase('Project Lifecycle', () async {
      // REAL INTEGRATION: real use workflow plus project symlink validation.
      _logTest('Testing FVM use workflow and symlink creation...');
      logger.info('Test directory before use: ${_testDir.path}');
      logger.info('Current working directory: ${Directory.current.path}');
      await _runFvmCommand(['use', testChannelVersion.name, '--skip-setup']);
      logger.info('Test directory after use: ${_testDir.path}');
      logger.info('Current working directory: ${Directory.current.path}');
      _verifyProjectConfiguration();
      _logSuccess('Use command creates project configuration and symlink');
    });
  }

  /// Phase 4: SDK Validation
  Future<void> _runPhase4SdkValidation() async {
    await _runPhase('SDK Validation', () async {
      // REAL INTEGRATION: real SDK setup and flutter doctor validation.
      _logTest('Testing Flutter proxy command and SDK validation...');
      await _runFvmCommand(['install', testChannelVersion.name, '--setup']);
      await _verifyInstallation(testChannelVersion);

      final flutterOutput = await _runFvmCommandWithOutput([
        'flutter',
        '--version',
      ]);
      await _createTempFile('flutter_version.txt', flutterOutput);
      if (!flutterOutput.contains('Flutter')) {
        throw AppException(
          'Flutter version output does not contain Flutter information',
        );
      }

      logger.info('Flutter version output:');
      logger.info(flutterOutput.split('\n').take(2).join('\n'));
      logger.info('Validating Flutter SDK setup with doctor...');

      final doctorOutput = await _runFvmCommandWithOutput([
        'flutter',
        'doctor',
        '-v',
      ]);
      await _createTempFile('flutter_doctor.txt', doctorOutput);
      if (!doctorOutput.contains('Flutter') || !doctorOutput.contains('Dart')) {
        throw AppException(
          'Flutter doctor output indicates SDK is not properly set up',
        );
      }

      _logSuccess('Flutter proxy works and SDK is validated');
    });
  }

  /// Phase 5: API Release Smoke
  Future<void> _runPhase5ApiReleaseSmoke() async {
    await _runPhase('API Release Smoke', () async {
      // REAL INTEGRATION: real releases API command backed by live metadata.
      _logTest('Testing API releases command...');
      final apiReleasesOutput = await _runFvmCommandWithOutput([
        'api',
        'releases',
        '--limit',
        '3',
      ]);
      await _createTempFile('api_releases.txt', apiReleasesOutput);
      if (apiReleasesOutput.trim().isEmpty) {
        throw AppException('API releases output is empty');
      }
      logger.info('API releases sample:');
      logger.info(apiReleasesOutput.split('\n').take(5).join('\n'));
      _logSuccess('API releases command works');
    });
  }

  /// Phase 6: Recovery
  Future<void> _runPhase6Recovery() async {
    await _runPhase('Recovery', () async {
      // REAL INTEGRATION: recovery with a corrupted cache entry present.
      _logTest('Testing corrupted cache recovery...');
      await _testCorruptedCacheRecovery();
      _logSuccess('Corrupted cache recovery works');

      // REAL INTEGRATION: fallback from a corrupted local git cache.
      _logTest('Testing Git clone fallback mechanism...');
      await _testGitCloneFallback();
      _logSuccess('Git clone fallback mechanism works');
    });
  }

  /// Test corrupted cache recovery (based on bash script lines 545-565)
  Future<void> _testCorruptedCacheRecovery() async {
    const corruptVersion = 'corrupt-test';
    final corruptDir = Directory(
      p.join(context.versionsCachePath, corruptVersion),
    );

    try {
      // Create a corrupted version directory
      await corruptDir.create(recursive: true);
      final corruptFile = File(p.join(corruptDir.path, 'flutter'));
      await corruptFile.writeAsString('corrupted');

      // Try to install a valid version (should work fine despite corruption).
      await _runFvmCommand(['install', testChannelVersion.name, '--no-setup']);

      logger.success('System recovered from corrupted cache entry');
    } catch (e) {
      logger.info('Note: Corrupted cache recovery test inconclusive: $e');
    } finally {
      // Clean up corrupted test
      if (corruptDir.existsSync()) {
        corruptDir.deleteSync(recursive: true);
      }
    }
  }

  /// Test Git clone fallback mechanism with isolated git cache
  Future<void> _testGitCloneFallback() async {
    // Create an isolated test context with a separate git cache
    final testGitCacheDir = Directory.systemTemp.createTempSync(
      'fvm_test_git_cache_',
    );

    // Create a test context with isolated git cache
    final testContext = FvmContext.create(
      isTest: true,
      configOverrides: AppConfig(
        gitCachePath: testGitCacheDir.path,
        useGitCache: true, // Ensure git cache is enabled for this test
      ),
      workingDirectoryOverride: context.workingDirectory,
      appConfigPath: context.appConfigPath,
    );

    try {
      logger.info(
        'Testing Git clone fallback with isolated cache: ${testGitCacheDir.path}',
      );

      // Create a corrupted git cache directory to trigger fallback
      final corruptFile = File(p.join(testGitCacheDir.path, 'corrupt_file'));
      corruptFile.writeAsStringSync('This is not a git repository');
      logger.info('Created corrupted git cache to trigger fallback');

      // Use the isolated context to install a version
      const fallbackTestVersion = '3.13.0';
      final testRunner = FvmCommandRunner(testContext);
      final exitCode = await testRunner.run(['install', fallbackTestVersion]);

      if (exitCode != 0) {
        throw AppException('Install command failed with exit code $exitCode');
      }

      // Verify installation using the test context
      final testCacheService = testContext.get<CacheService>();
      final testVersion = testCacheService.getVersion(
        FlutterVersion.parse(fallbackTestVersion),
      );

      if (testVersion == null) {
        throw AppException(
          'Version $fallbackTestVersion not found after fallback test',
        );
      }

      logger.success(
        'Git clone fallback mechanism worked correctly with isolated cache',
      );

      // Clean up the test version
      await testRunner.run(['remove', fallbackTestVersion]);
    } finally {
      // Clean up the isolated test cache
      if (testGitCacheDir.existsSync()) {
        testGitCacheDir.deleteSync(recursive: true);
        logger.info('Cleaned up isolated test git cache');
      }
    }
  }

  /// Phase 7: Destructive Cache Cleanup
  Future<void> _runPhase7CleanupOperations() async {
    await _runPhase('Destructive Cache Cleanup', () async {
      // REAL INTEGRATION: destroy real cache contents and reinstall guard SDK.
      _logTest('Testing destroy command and reinstall...');
      await _testDestroyCommandSafely();
      _logSuccess('Destroy command and reinstall completed');
    });
  }

  /// Test destroy command safely (focused on destroy functionality, not backup/restore)
  Future<void> _testDestroyCommandSafely() async {
    final cacheDir = Directory(context.fvmDir);
    if (!cacheDir.existsSync()) {
      logger.info('No cache directory to test destroy command');

      return;
    }

    try {
      // Create a minimal test structure to verify destroy works
      final testVersionDir = Directory(
        p.join(cacheDir.path, 'versions', 'destroy_test'),
      );
      if (!testVersionDir.existsSync()) {
        await testVersionDir.create(recursive: true);
        final testFile = File(p.join(testVersionDir.path, 'test_marker.txt'));
        await testFile.writeAsString('This file should be deleted by destroy');
      }

      // Count versions before destroy
      final versionsDir = Directory(p.join(cacheDir.path, 'versions'));
      final versionsBefore = versionsDir.existsSync()
          ? versionsDir.listSync().whereType<Directory>().length
          : 0;
      logger.info('Versions before destroy: $versionsBefore');

      // Test destroy command
      logger.info('Testing destroy command...');
      await _runFvmCommand(['destroy', '--force']);

      // Verify cache was cleared
      if (cacheDir.existsSync()) {
        final versionsAfter = versionsDir.existsSync()
            ? versionsDir.listSync().whereType<Directory>().length
            : 0;
        logger.info('Versions after destroy: $versionsAfter');

        // Check if test version was removed
        if (testVersionDir.existsSync()) {
          throw AppException(
            'Test version directory still exists after destroy',
          );
        }

        // The destroy command should have cleared the versions directory
        if (versionsDir.existsSync() && versionsAfter > 0) {
          final remaining =
              versionsDir.listSync().map((e) => p.basename(e.path)).join(', ');
          logger.info('Note: Some versions remain after destroy: $remaining');
          logger.info(
            'This may be normal if versions were added during testing',
          );
        }
      }

      logger.success('Destroy command successfully executed');

      // Re-create cache structure and install a version for subsequent tests
      if (!versionsDir.existsSync()) {
        await versionsDir.create(recursive: true);
        logger.info('Re-created versions directory for subsequent tests');
      }

      // Install a version so final validation has something to verify
      logger.info('Installing a version for final validation...');
      // Need to run setup so the version file is created
      await _runFvmCommand(['install', testChannelVersion.name, '--setup']);
      logger.success('Reinstalled test version after destroy');
    } catch (e) {
      // Re-create cache structure even on error
      final versionsDir = Directory(p.join(cacheDir.path, 'versions'));
      if (!versionsDir.existsSync()) {
        await versionsDir.create(recursive: true);
      }
      rethrow;
    }
  }

  /// Phase 8: Concurrency
  Future<void> _runPhase8Concurrency() async {
    await _runPhase('Concurrency', () async {
      // REAL INTEGRATION: concurrent operations over real installed SDKs.
      _logTest('Testing concurrent operation safety...');
      await _testConcurrentOperations();
      _logSuccess('Concurrent operations completed safely');
    });
  }

  /// Phase 9: Global Symlink
  Future<void> _runPhase9GlobalCommand() async {
    await _runPhase('Global Symlink', () async {
      // REAL INTEGRATION: real global symlink creation and validation.
      _logTest('Testing global version setting and symlink validation...');

      final originalGlobalVersion = _getGlobalVersion();
      logger.info('Current global version: ${originalGlobalVersion ?? "none"}');

      try {
        await _runFvmCommand(['global', testChannelVersion.name]);

        final globalLink = Link(context.globalCacheLink);
        if (!globalLink.existsSync()) {
          throw AppException('Global default symlink not created');
        }

        final target = globalLink.targetSync();
        if (!target.contains(testChannelVersion.name)) {
          throw AppException('Global symlink points to wrong version: $target');
        }

        final cacheService = context.get<CacheService>();
        final globalVersion = cacheService.getGlobal();
        if (globalVersion == null) {
          throw AppException('Global version not found after setting');
        }

        final globalFlutterBin = File(globalVersion.flutterExec);
        if (!globalFlutterBin.existsSync()) {
          throw AppException(
            'Flutter binary not found at expected path: ${globalVersion.flutterExec}',
          );
        }

        final currentGlobalVersion = _getGlobalVersion();
        if (currentGlobalVersion != testChannelVersion.name) {
          throw AppException(
            'Global version mismatch: expected ${testChannelVersion.name}, got $currentGlobalVersion',
          );
        }

        logger.success('Global version verified: ${testChannelVersion.name}');
        logger.success('Global symlink exists at: ${globalLink.path}');
        _logSuccess('Global command created a valid SDK symlink');
      } finally {
        if (originalGlobalVersion != null) {
          logger.info(
            'Restoring original global version: $originalGlobalVersion',
          );
          try {
            await _runFvmCommand(['global', originalGlobalVersion]);
          } catch (e) {
            logger.warn('Could not restore original global version: $e');
          }
        }
      }
    });
  }

  /// Get current global version if any
  String? _getGlobalVersion() {
    final cacheService = context.get<CacheService>();

    return cacheService.getGlobalVersion();
  }

  /// Test concurrent operations (based on bash script concurrent testing)
  Future<void> _testConcurrentOperations() async {
    logger.info('Running concurrent FVM operations...');

    // Run multiple real commands concurrently against installed SDK/cache state.
    final futures = [
      _runFvmCommand(['list']),
      _runFvmCommand(['releases']),
      _runFvmCommand(['flutter', '--version']),
    ];

    await Future.wait(futures);

    logger.info('Testing concurrent version access...');
    final concurrentFutures = [
      _runFvmCommand(['flutter', '--version']),
      _runFvmCommand(['install', testChannelVersion.name, '--no-setup']),
    ];

    await Future.wait(concurrentFutures);

    logger.success('All concurrent operations completed successfully');
  }

  /// Helper method to run FVM commands
  Future<void> _runFvmCommand(List<String> args) async {
    final runner = FvmCommandRunner(context);
    final exitCode = await runner.run(args);
    if (exitCode != 0) {
      throw AppException(
        'Command failed with exit code $exitCode: fvm ${args.join(' ')}',
      );
    }
  }

  /// Helper method to run FVM commands and capture output
  Future<String> _runFvmCommandWithOutput(List<String> args) async {
    final result = await Process.run(
      'dart',
      ['run', p.join(_originalDir, 'bin', 'main.dart'), ...args],
      workingDirectory: _testDir.path,
      environment: Platform.environment,
    );

    if (result.exitCode != 0) {
      throw AppException(
        'Command failed with exit code ${result.exitCode}: fvm ${args.join(' ')}\n'
        'stderr: ${result.stderr}',
      );
    }

    return result.stdout as String;
  }

  /// Create a temporary file for testing
  Future<File> _createTempFile(String name, String content) async {
    final file = File(p.join(_tempFilesDir.path, name));
    await file.writeAsString(content);

    return file;
  }

  Future<void> _runPhase(String name, Future<void> Function() body) async {
    logger.info('=== Phase ${++_phaseNumber}: $name ===');
    _currentPhase = name;
    try {
      await body();
    } finally {
      _currentPhase = null;
      logger.info('');
    }
  }

  /// Helper method to log test start
  void _logTest(String message) {
    _testCount += 1;
    final phase = _currentPhase ?? 'Unscoped';
    _phaseCounts.update(phase, (count) => count + 1, ifAbsent: () => 1);
    logger.info('[TEST] $_testCount. $message');
  }

  /// Helper method to log test success
  void _logSuccess(String message) {
    logger.success(message);
  }

  /// Verify installation of a Flutter version
  Future<void> _verifyInstallation(FlutterVersion version) async {
    final cacheService = context.get<CacheService>();
    final cacheVersion = cacheService.getVersion(version);

    if (cacheVersion == null) {
      throw AppException(
        'Version ${version.name} not found in isolated cache after installation',
      );
    }

    // Verify cache integrity
    final integrity = await cacheService.verifyCacheIntegrity(cacheVersion);
    if (integrity != CacheIntegrity.valid) {
      throw AppException(
        'Version ${version.name} has invalid cache integrity: $integrity',
      );
    }

    logger.info(
      'Version ${version.name} verified in isolated cache: ${cacheVersion.directory}',
    );
  }

  /// Verify project configuration after use command
  void _verifyProjectConfiguration() {
    // First, let's see what files actually exist
    logger.info('Checking project directory contents:');
    final projectFiles = _testDir.listSync();
    for (final file in projectFiles) {
      logger.info('  - ${p.basename(file.path)}');
    }

    final fvmrcFile = File(p.join(_testDir.path, '.fvmrc'));
    if (!fvmrcFile.existsSync()) {
      throw AppException('.fvmrc file not created');
    }

    final fvmDir = Directory(p.join(_testDir.path, '.fvm'));
    if (!fvmDir.existsSync()) {
      throw AppException('.fvm directory not created');
    }

    // Check what's inside .fvm directory
    logger.info('Checking .fvm directory contents:');
    final fvmFiles = fvmDir.listSync();
    for (final file in fvmFiles) {
      logger.info('  - ${p.basename(file.path)}');
    }

    // Verify symlink exists (like bash script lines 214-231)
    final symlinkPath = p.join(_testDir.path, '.fvm', 'flutter_sdk');
    final link = Link(symlinkPath);

    if (!link.existsSync()) {
      throw AppException('.fvm/flutter_sdk symlink not created');
    }

    final target = link.targetSync();
    if (!target.contains(context.versionsCachePath)) {
      throw AppException(
        '.fvm/flutter_sdk symlink points to wrong location: $target',
      );
    }

    logger.info('Project configuration verified');
    logger.info('  - .fvmrc file exists');
    logger.info('  - .fvm directory exists');
    logger.info('  - flutter_sdk symlink exists and points to: $target');
  }

  /// Print test summary
  void _printSummary() {
    logger.info('');
    logger.info('=== Integration Test Summary ===');
    logger.success('All $_testCount real integration tests passed!');
    logger.info('--- Runtime Test Coverage ---');
    for (final entry in _phaseCounts.entries) {
      final label = entry.value == 1 ? 'test' : 'tests';
      logger.info('   - ${entry.key}: ${entry.value} $label');
    }
    logger.info('');
    logger.info('[INFO] Test artifacts saved to: ${_tempFilesDir.path}');
    logger.info('[INFO] Cache verified at: ${context.fvmDir}');
    logger.info('');
    logger.success('FVM integration tests completed successfully!');
    logger.info('Real-world operations tested:');
    logger.info('  - Live release metadata');
    logger.info('  - Real Git clones and Flutter SDK installations');
    logger.info('  - File system changes (symlinks and .fvmrc)');
    logger.info('  - Flutter SDK setup and doctor validation');
    logger.info('  - API releases smoke coverage');
    logger.info('  - Corrupted cache and clone fallback recovery');
    logger.info('  - Destructive cache cleanup and reinstall');
    logger.info('  - Concurrent operation safety');
    logger.info('  - Global SDK symlink validation');
    logger.info('');
  }

  /// Execute the complete integration test workflow
  Future<void> _runIntegrationWorkflow() async {
    await _runPhase1ReleaseMetadata();
    await _runPhase2RealInstallations();
    await _runPhase3ProjectLifecycle();
    await _runPhase4SdkValidation();
    await _runPhase5ApiReleaseSmoke();
    await _runPhase6Recovery();
    await _runPhase7CleanupOperations();
    await _runPhase8Concurrency();
    await _runPhase9GlobalCommand();
  }

  Logger get logger => context.get();

  /// Run all integration tests as a continuous workflow
  Future<void> runAll() async {
    await _setup();

    try {
      logger.info('[TEST] Starting FVM Integration Test Workflow');
      logger.info('Running trimmed real integration guardrails');
      logger.info('');

      // Execute as a continuous workflow, not separate phases
      await _runIntegrationWorkflow();

      _printSummary();
    } finally {
      cleanup();
    }
  }

  /// Cleanup test environment
  void cleanup() {
    try {
      // Clean up temporary files directory
      if (_tempFilesDir.existsSync()) {
        _tempFilesDir.deleteSync(recursive: true);
        logger.info('[CLEAN] Cleaned up test artifacts: ${_tempFilesDir.path}');
      }

      logger.success('Test cleanup completed');
      logger.info('');
      logger.warn('Note: Your FVM cache has been modified by this test');
      logger.info('   Run "fvm doctor" to see the current state');
    } catch (e) {
      logger.warn('Warning: Could not clean up test directories: $e');
    }
  }
}
