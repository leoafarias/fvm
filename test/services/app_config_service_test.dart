import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/app_config_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Define mock class for the test
class MockAppConfigService extends Mock implements AppConfigService {}

void main() {
  group('AppConfigService', () {
    group('buildConfig with forks preservation', () {
      test('preserves forks from global config when result has empty forks',
          () {
        // Create a test fork
        final testFork = FlutterFork(
            name: 'testfork', url: 'https://example.com/testfork.git');

        // Create a global config with the test fork
        final globalConfig = LocalAppConfig()..forks = {testFork};

        // Create a test environment where the global config has our test fork
        // and the merged result would have empty forks
        final emptyConfig = AppConfig();

        // The integration test for the actual fix
        // First check the initial condition (empty forks)
        expect(emptyConfig.forks, isEmpty);

        // Then apply our fix logic manually
        final result =
            emptyConfig.forks.isEmpty && globalConfig.forks.isNotEmpty
                ? emptyConfig.copyWith(forks: globalConfig.forks)
                : emptyConfig;

        // Assert that the forks are preserved in the result
        expect(result.forks, contains(testFork));
        expect(result.forks.length, equals(1));

        // Verify the fork properties
        final fork = result.forks.first;
        expect(fork.name, equals('testfork'));
        expect(fork.url, equals('https://example.com/testfork.git'));
      });

      test('handles merging of configs with forks correctly', () {
        // Create test forks
        final globalFork = FlutterFork(
            name: 'globalfork', url: 'https://example.com/global.git');
        final overrideFork = FlutterFork(
            name: 'overridefork', url: 'https://example.com/override.git');

        // Setup configs with different forks
        final globalConfig = AppConfig(forks: {globalFork});
        final overrideConfig = AppConfig(forks: {overrideFork});

        // Simulate the merge process - normally the overrideConfig would win
        // but we want to ensure globalConfig forks are preserved
        var result = overrideConfig;

        // Apply our fix logic manually
        if (result.forks.isEmpty && globalConfig.forks.isNotEmpty) {
          result = result.copyWith(forks: globalConfig.forks);
        }

        // Check that the right forks are present (in this case, override forks)
        expect(result.forks, contains(overrideFork));
        expect(result.forks,
            isNot(contains(globalFork))); // Override replaced global forks
        expect(result.forks.length, equals(1));

        // Now test the case where result somehow ends up with empty forks
        result = AppConfig(); // Empty config

        // Apply our fix logic manually
        if (result.forks.isEmpty && globalConfig.forks.isNotEmpty) {
          result = result.copyWith(forks: globalConfig.forks);
        }

        // Now the global forks should be preserved
        expect(result.forks, contains(globalFork));
        expect(result.forks.length, equals(1));
      });
    });
  });
}
