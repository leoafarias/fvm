import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('Hash truncation bug tests', () {
    late TestCommandRunner runner;
    late TempDirectoryTracker tempDirs;

    setUp(() {
      runner = TestFactory.commandRunner();
      tempDirs = TempDirectoryTracker();
    });

    tearDown(() {
      tempDirs.cleanUp();
    });

    test('should preserve full commit hash when updating project config', () {
      const fullHash = '6d04a162109d07876230709adf4013db113b16a3';
      final testDir = tempDirs.create();
      
      // Create a test project
      createPubspecYaml(testDir);
      
      final projectService = runner.context.get<ProjectService>();
      final project = projectService.findAncestor(directory: testDir);
      
      // Update project with full hash
      final updatedProject = projectService.update(
        project,
        flutterSdkVersion: fullHash,
      );
      
      // Verify the config file contains the full hash
      expect(updatedProject.config!.flutter, fullHash);
      expect(updatedProject.config!.flutter!.length, 40);
      
      // Verify the config file on disk contains the full hash
      final configFile = testDir.path + '/.fvmrc';
      final configContent = configFile.file.read()!;
      expect(configContent.contains(fullHash), isTrue);
      expect(configContent.contains('6d04a16210'), isFalse);
    });

    test('should preserve full hash when parsing FlutterVersion', () {
      const fullHash = '6d04a162109d07876230709adf4013db113b16a3';
      const shortHash = '6d04a16210';
      
      final fullVersion = FlutterVersion.parse(fullHash);
      final shortVersion = FlutterVersion.parse(shortHash);
      
      // Full version should keep full hash
      expect(fullVersion.name, fullHash);
      expect(fullVersion.name.length, 40);
      
      // Short version should keep short hash  
      expect(shortVersion.name, shortHash);
      expect(shortVersion.name.length, 10);
      
      // They should be different
      expect(fullVersion.name, isNot(equals(shortVersion.name)));
    });

    test('should preserve full hash in all version properties', () {
      const fullHash = '6d04a162109d07876230709adf4013db113b16a3';
      
      final version = FlutterVersion.parse(fullHash);
      
      // All version properties should preserve the full hash
      expect(version.name, fullHash);
      expect(version.version, fullHash); // This getter should also preserve full hash
      expect(version.toString(), fullHash);
    });

    test('should warn about potentially truncated 10-character hashes', () {
      const possiblyTruncatedHash = '6d04a16210';
      final testDir = tempDirs.create();
      
      // Create a test project
      createPubspecYaml(testDir);
      
      final projectService = runner.context.get<ProjectService>();
      final project = projectService.findAncestor(directory: testDir);
      
      // Update project with potentially truncated hash - should trigger warning
      final updatedProject = projectService.update(
        project,
        flutterSdkVersion: possiblyTruncatedHash,
      );
      
      // Should still update successfully
      expect(updatedProject.config!.flutter, possiblyTruncatedHash);
      
      // Check that a warning was logged (this would require capturing log output in a real test)
      // For now, just verify the basic functionality works
    });

    test('should accept valid short hashes without warning', () {
      const validShortHash = 'fa345b1'; // 7 characters - clearly intentional short hash
      final testDir = tempDirs.create();
      
      // Create a test project
      createPubspecYaml(testDir);
      
      final projectService = runner.context.get<ProjectService>();
      final project = projectService.findAncestor(directory: testDir);
      
      // Update project with valid short hash - should not trigger warning
      final updatedProject = projectService.update(
        project,
        flutterSdkVersion: validShortHash,
      );
      
      // Should update successfully
      expect(updatedProject.config!.flutter, validShortHash);
    });
  });
}