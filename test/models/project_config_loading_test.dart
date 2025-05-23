import 'dart:io';
import 'package:fvm/src/models/project_model.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = createTempDir('project_config_loading_test');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('Project configuration loading edge cases', () {
    test('loads project without configuration', () {
      // Create a directory without any config files
      final projectDir = Directory(tempDirectory.path);

      // Load the project
      final project = Project.loadFromDirectory(projectDir);

      // Verify the project is loaded but has no config
      expect(project.path, equals(projectDir.path));
      expect(project.hasConfig, isFalse);
      expect(project.config, isNull);
      expect(project.pinnedVersion, isNull);
      expect(project.flavors, isEmpty);
    });

    test('loads project with empty configuration file', () {
      final projectDir = Directory(tempDirectory.path);

      // Create an empty config file
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('{}');

      // Load the project
      final project = Project.loadFromDirectory(projectDir);

      // Empty JSON object should be considered a valid config
      expect(project.hasConfig, isTrue);
      expect(project.config, isNotNull);
      expect(project.pinnedVersion, isNull);
      expect(project.flavors, isEmpty);
    });

    test('handles invalid JSON configuration gracefully', () {
      final projectDir = Directory(tempDirectory.path);

      // Create an invalid JSON config file
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('{ this is not valid json }');

      // This should throw a FormatException but ProjectConfig.loadFromDirectory should handle it
      // We need to wrap this in a try-catch to verify it doesn't crash
      try {
        // Load the project
        final project = Project.loadFromDirectory(projectDir);

        // Project should be loaded but config should be null
        expect(project.path, equals(projectDir.path));
        expect(project.hasConfig, isFalse);
        expect(project.config, isNull);
      } catch (e) {
        fail(
            'Project.loadFromDirectory should handle invalid JSON gracefully: $e');
      }
    });

    test('loads project with minimal valid configuration', () {
      final projectDir = Directory(tempDirectory.path);

      // Create a minimal config with just a flutter version
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('{"flutter": "3.10.0"}');

      // Load the project
      final project = Project.loadFromDirectory(projectDir);

      // Should have a valid config
      expect(project.hasConfig, isTrue);
      expect(project.config, isNotNull);
      expect(project.pinnedVersion?.name, equals('3.10.0'));
    });

    test('loads project with legacy configuration', () {
      final projectDir = Directory(tempDirectory.path);

      // Create only a legacy config file in the .fvm directory
      final fvmDir = Directory(p.join(projectDir.path, '.fvm'));
      fvmDir.createSync();

      final legacyConfigFile = File(p.join(fvmDir.path, 'fvm_config.json'));
      legacyConfigFile.writeAsStringSync('{"flutterSdkVersion": "3.10.0"}');

      // Load the project
      final project = Project.loadFromDirectory(projectDir);

      // Legacy config files should now be loaded properly
      expect(project.path, equals(projectDir.path));
      expect(project.hasConfig, isTrue);
      expect(project.config, isNotNull);
      expect(project.pinnedVersion?.name, equals('3.10.0'));
    });

    test('loads new configuration format', () {
      final projectDir = Directory(tempDirectory.path);

      // Create a new config file
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('{"flutter": "3.10.0"}');

      // Create a legacy config with a different version (in .fvm directory)
      final fvmDir = Directory(p.join(projectDir.path, '.fvm'));
      fvmDir.createSync();
      final legacyConfigFile = File(p.join(fvmDir.path, 'fvm_config.json'));
      legacyConfigFile.writeAsStringSync('{"flutterSdkVersion": "2.5.0"}');

      // Load the project
      final project = Project.loadFromDirectory(projectDir);

      // Should load the new config
      expect(project.hasConfig, isTrue);
      expect(project.config, isNotNull);
      expect(project.pinnedVersion?.name, equals('3.10.0'));
    });

    test('loads configuration with flavors', () {
      final projectDir = Directory(tempDirectory.path);

      // Create a config with flavors
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('''
      {
        "flutter": "3.10.0",
        "flavors": {
          "dev": "beta",
          "prod": "stable"
        }
      }
      ''');

      // Load the project
      final project = Project.loadFromDirectory(projectDir);

      // Verify flavors are loaded correctly
      expect(project.hasConfig, isTrue);
      expect(project.config, isNotNull);
      expect(project.pinnedVersion?.name, equals('3.10.0'));
      expect(project.flavors.length, equals(2));
      expect(project.flavors['dev'], equals('beta'));
      expect(project.flavors['prod'], equals('stable'));
    });

    test('loads configuration with custom settings', () {
      final projectDir = Directory(tempDirectory.path);

      // Create a config with custom settings
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('''
      {
        "flutter": "3.10.0",
        "privilegedAccess": false,
        "cachePath": "/custom/cache/path",
        "updateVscodeSettings": false
      }
      ''');

      // Load the project
      final project = Project.loadFromDirectory(projectDir);

      // Verify custom settings are loaded correctly
      expect(project.hasConfig, isTrue);
      expect(project.config?.privilegedAccess, isFalse);
      expect(project.config?.cachePath, equals('/custom/cache/path'));
      expect(project.config?.updateVscodeSettings, isFalse);
    });

    test('handles null values in configuration', () {
      final projectDir = Directory(tempDirectory.path);

      // Create a config with null values
      final configFile = File(p.join(projectDir.path, '.fvmrc'));
      configFile.writeAsStringSync('''
      {
        "flutter": "3.10.0",
        "flavors": null,
        "privilegedAccess": null,
        "cachePath": null
      }
      ''');

      // Load the project
      final project = Project.loadFromDirectory(projectDir);

      // Null values should be handled gracefully
      expect(project.hasConfig, isTrue);
      expect(project.config, isNotNull);
      expect(project.pinnedVersion?.name, equals('3.10.0'));
      expect(project.flavors, isEmpty);
    });
  });
}
