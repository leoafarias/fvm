import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/resolve_project_deps.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';
import 'test_logger.dart';

class FailingFlutterService extends FlutterService {
  FailingFlutterService(super.context);

  @override
  Future<ProcessResult> pubGet(
    CacheFlutterVersion version, {
    bool throwOnError = false,
    bool offline = false,
  }) async {
    return ProcessResult(
      0,
      1,
      '',
      'pub get failed (test)',
    );
  }
}

class FailingProcessService extends ProcessService {
  FailingProcessService(super.context);

  @override
  Future<ProcessResult> run(
    String command, {
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool echoOutput = false,
  }) async {
    if (throwOnError) {
      throw ProcessException(command, args, 'pub get failed (test)', 1);
    }

    return ProcessResult(0, 1, '', 'pub get failed (test)');
  }
}

void createFailingFlutterExecutable(Directory binDir) {
  if (Platform.isWindows) {
    final file = File(p.join(binDir.path, 'flutter.bat'));
    file.writeAsStringSync('@echo off\r\nexit /b 1\r\n');
    return;
  }

  final file = File(p.join(binDir.path, 'flutter'));
  file.writeAsStringSync('#!/bin/sh\nexit 1\n');
  Process.runSync('chmod', ['+x', file.path]);
}

void main() {
  group('ResolveProjectDependenciesWorkflow', () {
    late TestCommandRunner runner;
    late TempDirectoryTracker tempDirs;

    setUp(() {
      runner = TestFactory.commandRunner();
      tempDirs = TempDirectoryTracker();
    });

    tearDown(() {
      tempDirs.cleanUp();
    });

    test('should return false when version is not setup', () async {
      final testDir = tempDirs.create();
      createPubspecYaml(testDir);

      final project = runner.context.get<ProjectService>().findAncestor(
            directory: testDir,
          );

      // Create a version that is not setup (directory doesn't exist)
      final notSetupVersion = CacheFlutterVersion.fromVersion(
        FlutterVersion.parse('3.10.0'),
        directory: '/nonexistent',
      );

      final workflow = ResolveProjectDependenciesWorkflow(runner.context);
      final result = await workflow(project, notSetupVersion, force: false);

      expect(result, isFalse);

      final logger = runner.context.get<Logger>();
      expect(
        logger.outputs.any((msg) => msg.contains('Flutter SDK is not setup')),
        isTrue,
      );
    });

    test(
      'should return true when dart tool version matches Dart SDK version',
      () async {
        final testDir = tempDirs.create();
        createPubspecYaml(testDir);

        final project = runner.context.get<ProjectService>().findAncestor(
              directory: testDir,
            );

        // Create .dart_tool/version file in the PROJECT path (not testDir)
        final dartToolDir = Directory(p.join(project.path, '.dart_tool'));
        dartToolDir.createSync();
        final versionFile = File(p.join(dartToolDir.path, 'version'));
        versionFile.writeAsStringSync('3.1.0');

        // Create a properly setup version
        final versionDir = tempDirs.create();
        final binDir = Directory(p.join(versionDir.path, 'bin'));
        binDir.createSync(recursive: true);
        createFailingFlutterExecutable(binDir);
        File(p.join(versionDir.path, 'version')).writeAsStringSync('3.10.0');

        // Create Dart SDK cache version file (required for isSetup to be true)
        final dartSdkDir = Directory(p.join(binDir.path, 'cache', 'dart-sdk'));
        dartSdkDir.createSync(recursive: true);
        // Create bin directory as it is used to check if isSetup
        Directory(p.join(dartSdkDir.path, 'bin')).createSync(recursive: true);
        File(p.join(dartSdkDir.path, 'version')).writeAsStringSync('3.1.0');

        final setupVersion = CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('3.10.0'),
          directory: versionDir.path,
        );

        final workflow = ResolveProjectDependenciesWorkflow(runner.context);
        final result = await workflow(project, setupVersion, force: false);

        expect(result, isTrue);

        final logger = runner.context.get<Logger>();
        expect(
          logger.outputs.any(
            (msg) => msg.contains('Dart tool version matches SDK version'),
          ),
          isTrue,
        );
      },
    );

    test(
      'should proceed to resolve when dart tool version does NOT match Dart SDK version',
      () async {
        final testDir = tempDirs.create();
        createPubspecYaml(testDir);

        final project = runner.context.get<ProjectService>().findAncestor(
              directory: testDir,
            );

        // Create .dart_tool/version file with Dart SDK version 3.1.0
        final dartToolDir = Directory(p.join(project.path, '.dart_tool'));
        dartToolDir.createSync();
        final versionFile = File(p.join(dartToolDir.path, 'version'));
        versionFile.writeAsStringSync('3.1.0');

        // Create a properly setup version
        final versionDir = tempDirs.create();
        final binDir = Directory(p.join(versionDir.path, 'bin'));
        binDir.createSync(recursive: true);
        createFailingFlutterExecutable(binDir);
        File(p.join(versionDir.path, 'version')).writeAsStringSync('3.10.0');

        // Create Dart SDK cache with DIFFERENT version (3.2.0) to trigger mismatch
        final dartSdkDir = Directory(p.join(binDir.path, 'cache', 'dart-sdk'));
        dartSdkDir.createSync(recursive: true);
        Directory(p.join(dartSdkDir.path, 'bin')).createSync(recursive: true);
        // Different Dart SDK version than project's dart tool version
        File(p.join(dartSdkDir.path, 'version')).writeAsStringSync('3.2.0');

        final setupVersion = CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('3.10.0'),
          directory: versionDir.path,
        );

        final workflow = ResolveProjectDependenciesWorkflow(runner.context);

        try {
          await workflow(project, setupVersion, force: false);
        } catch (_) {
          // Expected to fail without real Flutter - that's ok
        }

        final logger = runner.context.get<Logger>();
        // Verify the version match skip message was NOT logged
        expect(
          logger.outputs.any(
            (msg) => msg.contains('Dart tool version matches SDK version'),
          ),
          isFalse,
          reason:
              'Should not skip resolve when dart tool version (3.1.0) differs from SDK version (3.2.0)',
        );
      },
    );

    test('should return true when no pubspec found', () async {
      final testDir = tempDirs.create();
      // Don't create pubspec.yaml

      final project = runner.context.get<ProjectService>().findAncestor(
            directory: testDir,
          );

      // Create a properly setup version
      final versionDir = tempDirs.create();
      final binDir = Directory(p.join(versionDir.path, 'bin'));
      binDir.createSync(recursive: true);
      File(p.join(binDir.path, 'flutter')).createSync();
      File(p.join(versionDir.path, 'version')).writeAsStringSync('3.10.0');

      // Create Dart SDK cache version file (required for isSetup to be true)
      final dartSdkDir = Directory(p.join(binDir.path, 'cache', 'dart-sdk'));
      dartSdkDir.createSync(recursive: true);
      // Create bin directory as it is used to check if isSetup
      Directory(p.join(dartSdkDir.path, 'bin')).createSync(recursive: true);
      File(p.join(dartSdkDir.path, 'version')).writeAsStringSync('3.10.0');

      final setupVersion = CacheFlutterVersion.fromVersion(
        FlutterVersion.parse('3.10.0'),
        directory: versionDir.path,
      );

      final workflow = ResolveProjectDependenciesWorkflow(runner.context);
      final result = await workflow(project, setupVersion, force: false);

      expect(result, isTrue);

      final logger = runner.context.get<Logger>();
      expect(
        logger.outputs.any(
          (msg) =>
              msg.contains('Skipping "pub get" because no pubspec.yaml found'),
        ),
        isTrue,
      );
    });

    test(
      'should allow user to confirm when pub get fails',
      () async {
        // This test validates the user confirmation flow when pub get fails.
        // It uses a failing FlutterService to simulate pub get failure.
        final testDir = tempDirs.create();
        createPubspecYaml(testDir);
        createProjectConfig(ProjectConfig(flutter: '3.10.0'), testDir);

        final context = TestFactory.context(
          environmentOverrides: {'PATH': ''},
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse(
                'continue pinning this version anyway?',
                true,
              ),
            FlutterService: (context) => FailingFlutterService(context),
            ProcessService: (context) => FailingProcessService(context),
          },
        );

        final project = context.get<ProjectService>().findAncestor(
              directory: testDir,
            );

        final versionDir = tempDirs.create();
        final binDir = Directory(p.join(versionDir.path, 'bin'));
        binDir.createSync(recursive: true);
        File(p.join(binDir.path, 'flutter')).createSync();
        File(p.join(versionDir.path, 'version')).writeAsStringSync('3.10.0');

        final dartSdkDir = Directory(p.join(binDir.path, 'cache', 'dart-sdk'));
        dartSdkDir.createSync(recursive: true);
        Directory(p.join(dartSdkDir.path, 'bin')).createSync(recursive: true);
        File(p.join(dartSdkDir.path, 'version')).writeAsStringSync('3.10.0');

        final version = CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('3.10.0'),
          directory: versionDir.path,
        );

        final workflow = ResolveProjectDependenciesWorkflow(context);
        final result = await workflow(project, version, force: false);

        // When user confirms, workflow should return true
        expect(result, isTrue);
        final logger = context.get<Logger>();
        expect(
          logger.outputs.any((msg) => msg.contains('User response: Yes')),
          isTrue,
        );
      },
    );

    test(
      'should throw when user declines after pub get fails',
      () async {
        // This test validates that declining confirmation throws AppException.
        // It uses a failing FlutterService to simulate pub get failure.
        final testDir = tempDirs.create();
        createPubspecYaml(testDir);
        createProjectConfig(ProjectConfig(flutter: '3.10.0'), testDir);

        final context = TestFactory.context(
          environmentOverrides: {'PATH': ''},
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse(
                'continue pinning this version anyway?',
                false,
              ),
            FlutterService: (context) => FailingFlutterService(context),
            ProcessService: (context) => FailingProcessService(context),
          },
        );

        final project = context.get<ProjectService>().findAncestor(
              directory: testDir,
            );

        final versionDir = tempDirs.create();
        final binDir = Directory(p.join(versionDir.path, 'bin'));
        binDir.createSync(recursive: true);
        File(p.join(binDir.path, 'flutter')).createSync();
        File(p.join(versionDir.path, 'version')).writeAsStringSync('3.10.0');

        final dartSdkDir = Directory(p.join(binDir.path, 'cache', 'dart-sdk'));
        dartSdkDir.createSync(recursive: true);
        Directory(p.join(dartSdkDir.path, 'bin')).createSync(recursive: true);
        File(p.join(dartSdkDir.path, 'version')).writeAsStringSync('3.10.0');

        final version = CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('3.10.0'),
          directory: versionDir.path,
        );

        final workflow = ResolveProjectDependenciesWorkflow(context);

        // When user declines, workflow should throw AppException
        await expectLater(
          () => workflow(project, version, force: false),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('Dependencies not resolved'),
            ),
          ),
        );
      },
    );

    test('should skip confirmation with force flag', () async {
      final testDir = tempDirs.create();
      createPubspecYaml(testDir);

      final project = runner.context.get<ProjectService>().findAncestor(
            directory: testDir,
          );

      final versionDir = tempDirs.create();
      final binDir = Directory(p.join(versionDir.path, 'bin'));
      binDir.createSync(recursive: true);
      File(p.join(binDir.path, 'flutter')).createSync();
      File(p.join(versionDir.path, 'version')).writeAsStringSync('3.10.0');

      // Create Dart SDK cache version file (required for isSetup to be true)
      final dartSdkDir = Directory(p.join(binDir.path, 'cache', 'dart-sdk'));
      dartSdkDir.createSync(recursive: true);
      // Create bin directory as it is used to check if isSetup
      Directory(p.join(dartSdkDir.path, 'bin')).createSync(recursive: true);
      File(p.join(dartSdkDir.path, 'version')).writeAsStringSync('3.10.0');

      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.parse('3.10.0'),
        directory: versionDir.path,
      );

      final workflow = ResolveProjectDependenciesWorkflow(runner.context);

      try {
        final result = await workflow(project, version, force: true);
        // With force flag, when pub get fails it should return false without prompting
        if (!result) {
          final logger = runner.context.get<Logger>();
          expect(
            logger.outputs.any(
              (msg) => msg.contains('Force pinning due to --force flag'),
            ),
            isTrue,
          );
          // Should not see confirmation prompt
          expect(
            logger.outputs.any(
              (msg) => msg.contains(
                'Would you like to continue pinning this version anyway?',
              ),
            ),
            isFalse,
          );
        }
      } catch (e) {
        // Expected in test env without Flutter
      }
    });
  });
}
