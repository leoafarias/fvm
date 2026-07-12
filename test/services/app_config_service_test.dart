import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/app_config_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('AppConfigService', () {
    group('buildConfig', () {
      test('returns valid AppConfig', () {
        // Test that buildConfig returns a valid config
        final config = AppConfigService.buildConfig();
        expect(config, isA<AppConfig>());
      });

      test('applies overrides correctly', () {
        // Test that overrides are applied
        final overrides = AppConfig(
          privilegedAccess: true,
          cachePath: '/custom/cache',
        );

        final config = AppConfigService.buildConfig(overrides: overrides);

        expect(config.privilegedAccess, isTrue);
        expect(config.cachePath, equals('/custom/cache'));
      });
    });

    group('createAppConfig', () {
      test('handles null configs gracefully', () {
        // Test with all null configs except global (which is required)
        final globalConfig = LocalAppConfig();

        final result = AppConfigService.createAppConfig(
          globalConfig: globalConfig,
          envConfig: null,
          projectConfig: null,
          overrides: null,
        );

        // Should return a valid AppConfig
        expect(result, isA<AppConfig>());
      });

      test('merges multiple configs correctly', () {
        // Create configs with different settings
        final globalConfig = LocalAppConfig()
          ..cachePath = '/global/cache'
          ..privilegedAccess = false;

        final overrides = AppConfig(privilegedAccess: true);

        // Test the merge behavior
        final result = AppConfigService.createAppConfig(
          globalConfig: globalConfig,
          envConfig: null,
          projectConfig: null,
          overrides: overrides,
        );

        // Overrides should win for privilegedAccess
        expect(result.privilegedAccess, isTrue);
        // Global config should provide cachePath
        expect(result.cachePath, equals('/global/cache'));
      });

      test('merges updateMelosSettings with project precedence', () {
        final globalConfig = LocalAppConfig()..updateMelosSettings = false;

        final result = AppConfigService.createAppConfig(
          globalConfig: globalConfig,
          envConfig: null,
          projectConfig: const ProjectConfig(updateMelosSettings: true),
          overrides: null,
        );

        expect(result.updateMelosSettings, isTrue);
      });
    });

    group('configuration inputs', () {
      test('context environment overrides configure the app context', () {
        const flutterUrl = 'https://example.com/custom/flutter.git';
        final context = TestFactory.context(
          environmentOverrides: const {'FVM_FLUTTER_URL': flutterUrl},
        );

        expect(context.environment['FVM_FLUTTER_URL'], flutterUrl);
        expect(context.flutterUrl, flutterUrl);
      });

      test('context working directory determines project config', () {
        const flutterUrl = 'https://example.com/project/flutter.git';
        final projectDir = createTempDir();
        final nestedDir = Directory(p.join(projectDir.path, 'packages', 'app'))
          ..createSync(recursive: true);
        File(p.join(projectDir.path, kFvmConfigFileName)).writeAsStringSync(
          '{"flutterUrl":"$flutterUrl"}',
        );

        final context = TestFactory.context(
          workingDirectoryOverride: nestedDir.path,
        );

        expect(context.workingDirectory, nestedDir.path);
        expect(context.flutterUrl, flutterUrl);
      });

      test('relative context working directory discovers ancestor config', () {
        const flutterUrl = 'https://example.com/relative/flutter.git';
        final projectDir = createTempDir();
        final nestedDir = Directory(p.join(projectDir.path, 'packages', 'app'))
          ..createSync(recursive: true);
        File(p.join(projectDir.path, kFvmConfigFileName)).writeAsStringSync(
          '{"flutterUrl":"$flutterUrl"}',
        );
        final relativeNestedDir = p.relative(
          nestedDir.path,
          from: Directory.current.path,
        );

        final context = TestFactory.context(
          workingDirectoryOverride: relativeNestedDir,
        );

        expect(context.workingDirectory, relativeNestedDir);
        expect(context.flutterUrl, flutterUrl);
        expect(
          context.get<ProjectService>().findAncestor().path,
          projectDir.path,
        );
      });

      test('relative context working directory without config terminates', () {
        final workingDir = createTempDir();
        final relativeWorkingDir = p.relative(
          workingDir.path,
          from: Directory.current.path,
        );

        final context = TestFactory.context(
          workingDirectoryOverride: relativeWorkingDir,
        );

        expect(context.workingDirectory, relativeWorkingDir);
      });

      test('FVM_CACHE_PATH takes precedence over legacy FVM_HOME', () {
        final configFile = p.join(createTempDir().path, 'config.json');
        final legacyConfig = AppConfigService.buildConfig(
          appConfigPath: configFile,
          environment: const {'FVM_HOME': '/legacy/cache'},
        );
        final currentConfig = AppConfigService.buildConfig(
          appConfigPath: configFile,
          environment: const {
            'FVM_HOME': '/legacy/cache',
            'FVM_CACHE_PATH': '/current/cache',
          },
        );

        expect(legacyConfig.cachePath, '/legacy/cache');
        expect(currentConfig.cachePath, '/current/cache');
      });
    });
  });
}
