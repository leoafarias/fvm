import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  late TestCommandRunner testRunner;
  late ServicesProvider services;

  setUp(() {
    testRunner = TestFactory.commandRunner();

    services = testRunner.services;
  });

  group('Complete flow', () {
    test('Full project workflow', () async {
      final channel = 'stable';
      // Install the Flutter channel
      await testRunner.runOrThrow(['fvm', 'install', channel]);

      // Helper function to get cache version
      Future<CacheFlutterVersion?> getCacheVersion() async {
        return services.cache.getVersion(
          FlutterVersion.parse(channel),
        );
      }

      // Get the installed version
      var cacheVersion = await getCacheVersion();

      // Get the branch from Git
      final existingChannel = await services.git.getBranch(channel);

      // Verify installation succeeded
      expect(cacheVersion != null, true, reason: 'Install does not exist');
      expect(existingChannel, channel);

      // Verify version is not set up yet
      expect(
        cacheVersion?.isNotSetup,
        true,
        reason: 'Version should not be setup',
      );
      expect(
        cacheVersion?.isChannel,
        true,
        reason: 'Version should be channel',
      );
      expect(
        cacheVersion?.flutterSdkVersion,
        isNull,
        reason: 'Version should not have flutter sdk version',
      );
      expect(
        cacheVersion?.dartSdkVersion,
        isNull,
        reason: 'Version should not have dart sdk version',
      );

      // Verify project has no pinned version yet
      var project = services.project.findAncestor();
      expect(project.pinnedVersion, isNull);

      // Use the channel in the project, but skip setup
      await testRunner.runOrThrow(['fvm', 'use', channel, '--skip-setup']);

      // Reload project and version information
      project = services.project.findAncestor();
      cacheVersion = await getCacheVersion();

      // Verify project now has pinned version
      expect(project.pinnedVersion?.name, channel);

      // Verify version is still not set up (since we used --skip-setup)
      expect(
        cacheVersion?.isNotSetup,
        true,
        reason: 'Version should not be setup',
      );
      expect(
        cacheVersion?.isChannel,
        true,
        reason: 'Version should be channel',
      );
      expect(
        cacheVersion?.flutterSdkVersion,
        isNull,
        reason: 'Version should not have flutter sdk version',
      );
      expect(
        cacheVersion?.dartSdkVersion,
        isNull,
        reason: 'Version should not have dart sdk version',
      );
    });
  });
}
