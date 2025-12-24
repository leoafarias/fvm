import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/workflows/update_android_studio_settings.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('UpdateAndroidStudioSettingsWorkflow', () {
    late TestCommandRunner runner;
    late TempDirectoryTracker tempDirs;

    setUp(() {
      runner = TestFactory.commandRunner();
      tempDirs = TempDirectoryTracker();
    });

    tearDown(() {
      tempDirs.cleanUp();
    });

    Future<Project> _createProject({
      required Directory projectDir,
      ProjectConfig? config,
    }) async {
      createPubspecYaml(projectDir);
      createProjectConfig(config ?? const ProjectConfig(), projectDir);

      final fvmDir = Directory(p.join(projectDir.path, '.fvm'));
      fvmDir.createSync(recursive: true);

      final realSdk = Directory(
        p.join(projectDir.path, 'flutter_sdks', 'stable'),
      )..createSync(recursive: true);

      Directory(
        p.join(realSdk.path, 'bin', 'cache', 'dart-sdk', 'lib'),
      ).createSync(recursive: true);

      final flutterLink = Link(p.join(fvmDir.path, 'flutter_sdk'));
      if (flutterLink.existsSync()) {
        flutterLink.deleteSync();
      }
      flutterLink.createSync(realSdk.path);

      final ideaDir = Directory(p.join(projectDir.path, '.idea'));
      ideaDir.createSync(recursive: true);
      Directory(p.join(ideaDir.path, 'libraries')).createSync(recursive: true);

      final flutterSettingsFile = File(p.join(ideaDir.path, 'flutter.xml'));
      flutterSettingsFile.writeAsStringSync('''
<project version="4">
  <component name="FlutterSettings">
    <option name="FLUTTER_SDK_PATH" value="/old/flutter" />
  </component>
</project>
''');

      final dartSdkFile =
          File(p.join(ideaDir.path, 'libraries', 'Dart_SDK.xml'));
      dartSdkFile.writeAsStringSync('''
<component name="libraryTable">
  <library name="Dart SDK">
    <CLASSES>
      <root url="jar://file:///old/flutter/bin/cache/dart-sdk/lib/core.jar!/" />
      <root url="file:///old/flutter/bin/cache/dart-sdk/lib" />
    </CLASSES>
  </library>
</component>
''');

      final project = runner.context.get<ProjectService>().findAncestor(
            directory: projectDir,
          );

      // Ensure symlink resolves in tests.
      expect(
        Directory(p.join(project.localFvmPath, 'flutter_sdk')).existsSync(),
        isTrue,
      );

      return project;
    }

    test('skips when updateAndroidStudioSettings is false', () async {
      final projectDir = tempDirs.create();
      final project = await _createProject(
        projectDir: projectDir,
        config: const ProjectConfig(updateAndroidStudioSettings: false),
      );

      final workflow = UpdateAndroidStudioSettingsWorkflow(runner.context);

      await workflow(project);

      final flutterSettings =
          File(p.join(projectDir.path, '.idea', 'flutter.xml'))
              .readAsStringSync();
      expect(flutterSettings, contains('value="/old/flutter"'));

      final backupFile = File(
        p.join(projectDir.path, '.idea', 'flutter.xml.fvm.bak'),
      );
      expect(backupFile.existsSync(), isFalse);
    });

    test('updates FlutterSettings and Dart_SDK.xml and creates backups',
        () async {
      final projectDir = tempDirs.create();
      final project = await _createProject(projectDir: projectDir);
      final workflow = UpdateAndroidStudioSettingsWorkflow(runner.context);

      await workflow(project);

      final flutterSettingsFile =
          File(p.join(projectDir.path, '.idea', 'flutter.xml'));
      final flutterSettings = flutterSettingsFile.readAsStringSync();

      // Should contain the symlink path, NOT the resolved path.
      // This allows Android Studio to use the correct SDK when the symlink
      // target changes (e.g., when switching Flutter versions via 'fvm use').
      final symlinkPath = p.join(projectDir.path, '.fvm', 'flutter_sdk');
      expect(flutterSettings, contains('value="$symlinkPath"'));
      // Verify it does NOT contain the resolved SDK directory name
      expect(flutterSettings, isNot(contains('flutter_sdks/stable')));

      final dartSdkFile =
          File(p.join(projectDir.path, '.idea', 'libraries', 'Dart_SDK.xml'));
      final dartSdkContent = dartSdkFile.readAsStringSync();
      expect(
        dartSdkContent,
        contains(
          'jar://\$PROJECT_DIR\$/.fvm/flutter_sdk/bin/cache/dart-sdk/lib/core.jar!/',
        ),
      );
      expect(
        dartSdkContent,
        contains(
          'file://\$PROJECT_DIR\$/.fvm/flutter_sdk/bin/cache/dart-sdk/lib',
        ),
      );

      expect(
        File('${flutterSettingsFile.path}.fvm.bak').existsSync(),
        isTrue,
      );
      expect(
        File('${dartSdkFile.path}.fvm.bak').existsSync(),
        isTrue,
      );

      final beforeSecondRun = flutterSettingsFile.readAsStringSync();
      await workflow(project);
      final afterSecondRun = flutterSettingsFile.readAsStringSync();
      expect(afterSecondRun, equals(beforeSecondRun));
    });

    test('skips gracefully when .idea directory does not exist', () async {
      final projectDir = tempDirs.create();
      createPubspecYaml(projectDir);
      createProjectConfig(const ProjectConfig(), projectDir);

      // Create .fvm/flutter_sdk but NO .idea directory
      final fvmDir = Directory(p.join(projectDir.path, '.fvm'))..createSync();
      final realSdk = Directory(
        p.join(projectDir.path, 'flutter_sdks', 'stable'),
      )..createSync(recursive: true);
      Link(p.join(fvmDir.path, 'flutter_sdk')).createSync(realSdk.path);

      final project = runner.context.get<ProjectService>().findAncestor(
            directory: projectDir,
          );
      final workflow = UpdateAndroidStudioSettingsWorkflow(runner.context);

      // Should not throw - gracefully skips
      await workflow(project);

      // Verify .idea was not created
      expect(Directory(p.join(projectDir.path, '.idea')).existsSync(), isFalse);
    });

    test('skips gracefully when flutter_sdk symlink does not exist', () async {
      final projectDir = tempDirs.create();
      createPubspecYaml(projectDir);
      createProjectConfig(const ProjectConfig(), projectDir);

      // Create .idea but NO .fvm/flutter_sdk
      final ideaDir = Directory(p.join(projectDir.path, '.idea'))
        ..createSync(recursive: true);

      // Create a flutter.xml with existing settings
      final flutterXml = File(p.join(ideaDir.path, 'flutter.xml'));
      flutterXml.writeAsStringSync('''
<project version="4">
  <component name="FlutterSettings">
    <option name="FLUTTER_SDK_PATH" value="/old/flutter" />
  </component>
</project>
''');

      final project = runner.context.get<ProjectService>().findAncestor(
            directory: projectDir,
          );
      final workflow = UpdateAndroidStudioSettingsWorkflow(runner.context);

      // Should not throw - gracefully skips
      await workflow(project);

      // Verify flutter.xml was not modified
      final content = flutterXml.readAsStringSync();
      expect(content, contains('value="/old/flutter"'));

      // Verify no backup was created
      expect(
        File(p.join(ideaDir.path, 'flutter.xml.fvm.bak')).existsSync(),
        isFalse,
      );
    });

    test('adds FLUTTER_SDK_PATH when component exists but option is missing',
        () async {
      final projectDir = tempDirs.create();
      createPubspecYaml(projectDir);
      createProjectConfig(const ProjectConfig(), projectDir);

      // Create .fvm/flutter_sdk symlink
      final fvmDir = Directory(p.join(projectDir.path, '.fvm'))..createSync();
      final realSdk = Directory(
        p.join(projectDir.path, 'flutter_sdks', 'stable'),
      )..createSync(recursive: true);
      Link(p.join(fvmDir.path, 'flutter_sdk')).createSync(realSdk.path);

      // Create .idea with FlutterSettings but NO FLUTTER_SDK_PATH option
      final ideaDir = Directory(p.join(projectDir.path, '.idea'))
        ..createSync(recursive: true);
      final flutterXml = File(p.join(ideaDir.path, 'flutter.xml'));
      flutterXml.writeAsStringSync('''
<project version="4">
  <component name="FlutterSettings">
  </component>
</project>
''');

      final project = runner.context.get<ProjectService>().findAncestor(
            directory: projectDir,
          );
      final workflow = UpdateAndroidStudioSettingsWorkflow(runner.context);

      await workflow(project);

      final content = flutterXml.readAsStringSync();
      // Should have added FLUTTER_SDK_PATH option
      expect(content, contains('FLUTTER_SDK_PATH'));
      // Should use symlink path
      expect(content, contains('.fvm/flutter_sdk'));
    });
  });
}
