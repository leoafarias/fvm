
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/app_config_service.dart';
import 'package:test/test.dart';


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

        final overrides = AppConfig(
          privilegedAccess: true,
        );

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
    });
  });
}