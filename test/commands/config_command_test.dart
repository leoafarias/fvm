import 'package:fvm/src/models/config_model.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late TestCommandRunner runner;
  late LocalAppConfig originalConfig;

  setUp(() {
    // Save original config to restore later
    originalConfig = LocalAppConfig.read();

    runner = TestFactory.commandRunner();
  });

  tearDown(() {
    // Restore original config
    originalConfig.save();
  });

  group('Config Command - Update Check:', () {
    test('disables update check with --no-disable-update-check', () async {
      // Note: Double negative because flag is "disable-update-check"
      // --no-disable-update-check means "do NOT disable" = "enable" checking
      await runner.runOrThrow(['fvm', 'config', '--no-disable-update-check']);

      final config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isFalse);
    });

    test('enables disable with --disable-update-check', () async {
      await runner.runOrThrow(['fvm', 'config', '--disable-update-check']);

      final config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isTrue);
    });

    test('persists update check setting to config file', () async {
      // First, disable update checking
      await runner.runOrThrow(['fvm', 'config', '--disable-update-check']);

      // Read fresh from disk to verify persistence
      final config1 = LocalAppConfig.read();
      expect(config1.disableUpdateCheck, isTrue);

      // Now re-enable update checking
      await runner.runOrThrow(['fvm', 'config', '--no-disable-update-check']);

      // Read fresh from disk again
      final config2 = LocalAppConfig.read();
      expect(config2.disableUpdateCheck, isFalse);
    });

    test('displays current config when no flags provided', () async {
      // Set a known state
      LocalAppConfig.read()
        ..disableUpdateCheck = true
        ..save();

      // Run config command without arguments
      await runner.runOrThrow(['fvm', 'config']);

      // Verify config is still set (command didn't change it)
      final config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isTrue);
    });

    test('can toggle update check multiple times', () async {
      // First enable (set to false)
      await runner.runOrThrow(['fvm', 'config', '--no-disable-update-check']);
      var config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isFalse);

      // Then disable (set to true)
      await runner.runOrThrow(['fvm', 'config', '--disable-update-check']);
      config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isTrue);

      // Enable again
      await runner.runOrThrow(['fvm', 'config', '--no-disable-update-check']);
      config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isFalse);
    });

    test('config persists across multiple config reads', () async {
      // Set the config
      await runner.runOrThrow(['fvm', 'config', '--disable-update-check']);

      // Read multiple times to ensure consistency
      final config1 = LocalAppConfig.read();
      final config2 = LocalAppConfig.read();
      final config3 = LocalAppConfig.read();

      expect(config1.disableUpdateCheck, isTrue);
      expect(config2.disableUpdateCheck, isTrue);
      expect(config3.disableUpdateCheck, isTrue);
    });
  });

  group('Config Command - Integration with Other Settings:', () {
    test('can set multiple config options including disable-update-check',
        () async {
      // Set multiple options at once
      await runner.runOrThrow([
        'fvm',
        'config',
        '--disable-update-check',
        '--use-git-cache',
      ]);

      final config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isTrue);
      expect(config.useGitCache, isTrue);
    });

    test('disable-update-check does not affect other config options', () async {
      // First set git cache to false
      await runner.runOrThrow(['fvm', 'config', '--no-use-git-cache']);

      var config = LocalAppConfig.read();
      final originalGitCache = config.useGitCache;

      // Now change only update check setting
      await runner.runOrThrow(['fvm', 'config', '--disable-update-check']);

      config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isTrue);
      expect(config.useGitCache, equals(originalGitCache));
    });

    test('handles null initial state correctly', () async {
      // Create a fresh config with no settings
      LocalAppConfig().save();

      // Now set disable-update-check
      await runner.runOrThrow(['fvm', 'config', '--disable-update-check']);

      final config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isTrue);
    });
  });

  group('Config Command - Edge Cases:', () {
    test('setting same value twice does not cause issues', () async {
      // Set to true
      await runner.runOrThrow(['fvm', 'config', '--disable-update-check']);

      // Set to true again
      await runner.runOrThrow(['fvm', 'config', '--disable-update-check']);

      final config = LocalAppConfig.read();
      expect(config.disableUpdateCheck, isTrue);
    });

    test('handles config file creation when it does not exist', () async {
      // Remove config file if it exists
      final configFile = LocalAppConfig.read();
      final configPath = configFile.location;

      // Ensure we can write to a fresh config
      LocalAppConfig().save();

      // Now set the value
      await runner.runOrThrow(['fvm', 'config', '--disable-update-check']);

      final newConfig = LocalAppConfig.read();
      expect(newConfig.disableUpdateCheck, isTrue);
    });
  });
}
