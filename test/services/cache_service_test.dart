@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/cache_version_model.dart';
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

const key = Key('cache_service_test');
const _channel = 'beta';
const _version = '1.20.2';
void main() {
  setUpAll(() {
    final testDir = getFvmTestDir(key);
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });
  tearDownAll(() {
    final testDir = getFvmTestDir(key);
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });
  group('Cache Service Test:', () {
    testWithContext('Cache Version', key, () async {
      var validChannel =
          await CacheService.isVersionCached(ValidVersion(_channel));
      var validVersion =
          await CacheService.isVersionCached(ValidVersion(_version));
      expect(validChannel, null);
      expect(validVersion, null);

      await CacheService.cacheVersion(ValidVersion(_channel));
      await CacheService.cacheVersion(ValidVersion(_version));

      validChannel = await CacheService.isVersionCached(ValidVersion(_channel));
      validVersion = await CacheService.isVersionCached(ValidVersion(_version));
      expect(validChannel!.name, _channel);
      expect(validVersion!.name, _version);
    });

    testWithContext('Lists Cache Versions', key, () async {
      final versions = await CacheService.getAllVersions();
      expect(versions.length, 2);
    });

    testWithContext('Get Cache Versions by name', key, () async {
      final channel = await CacheService.getByVersionName(_channel);
      final version = await CacheService.getByVersionName(_version);
      expect(channel!.name, _channel);
      expect(version!.name, _version);
    });

    testWithContext('Verify cache integrity', key, () async {
      final channel = await CacheService.getByVersionName(_channel);
      final version = await CacheService.getByVersionName(_version);
      final invalidCache = CacheVersion('invalid_version');

      final isChannelValid = await CacheService.verifyIntegrity(channel!);
      final isVersionValid = await CacheService.verifyIntegrity(version!);
      final isInvalidValid = await CacheService.verifyIntegrity(invalidCache);

      expect(isChannelValid, true);
      expect(isVersionValid, true);
      expect(isInvalidValid, false);
    });

    testWithContext('Set/Get Global Cache Version ', key, () async {
      CacheVersion? globalVersion;
      bool isChanneGlobal, isVersionGlobal;
      globalVersion = await CacheService.getGlobal();
      expect(globalVersion, null);

      final channel = await CacheService.getByVersionName(_channel);
      final version = await CacheService.getByVersionName(_version);
      // Set channel as global
      await CacheService.setGlobal(channel!);
      globalVersion = await CacheService.getGlobal();
      isChanneGlobal = await CacheService.isGlobal(channel);
      isVersionGlobal = await CacheService.isGlobal(version!);

      expect(globalVersion!.name, channel.name);
      expect(isChanneGlobal, true);
      expect(isVersionGlobal, false);

      // Set version as global
      await CacheService.setGlobal(version);
      globalVersion = await CacheService.getGlobal();
      isChanneGlobal = await CacheService.isGlobal(channel);
      isVersionGlobal = await CacheService.isGlobal(version);

      expect(globalVersion!.name, version.name);
      expect(isChanneGlobal, false);
      expect(isVersionGlobal, true);
    });
  });
}
