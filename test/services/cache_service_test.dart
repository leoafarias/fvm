@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/cache_version_model.dart';
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

const _channel = 'beta';
const _version = '1.20.2';

void main() {
  groupWithContext('Cache Service Test:', () {
    testWithContext('Cache Version', () async {
      var validChannel = await CacheService.getVersionCache(
        ValidVersion(_channel),
      );
      var validVersion = await CacheService.getVersionCache(
        ValidVersion(_version),
      );
      expect(validChannel, null);
      expect(validVersion, null);

      await CacheService.cacheVersion(ValidVersion(_channel));
      await CacheService.cacheVersion(ValidVersion(_version));

      final cacheChannel =
          await CacheService.getVersionCache(ValidVersion(_channel));

      final cacheVersion =
          await CacheService.getVersionCache(ValidVersion(_version));

      final channelIntegrity =
          await CacheService.verifyCacheIntegrity(cacheChannel!);
      final versionIntegrity =
          await CacheService.verifyCacheIntegrity(cacheVersion!);
      final invalidIntegrity =
          await CacheService.verifyCacheIntegrity(CacheVersion('invalid'));

      final versions = await CacheService.getAllVersions();
      expect(versions.length, 2);

      forceUpdateFlutterSdkVersionFile(cacheVersion, '2.7.0');

      final cacheVersion2 =
          await CacheService.getVersionCache(ValidVersion(_version));
      final versionIntegrity2 =
          await CacheService.verifyCacheIntegrity(cacheVersion2!);

      expect(versionIntegrity, CacheIntegrity.valid);
      expect(channelIntegrity, CacheIntegrity.valid);
      expect(invalidIntegrity, CacheIntegrity.invalid);
      expect(versionIntegrity2, CacheIntegrity.versionMismatch);
    });

    testWithContext('Set/Get Global Cache Version ', () async {
      CacheVersion? globalVersion;
      bool isChanneGlobal, isVersionGlobal;
      globalVersion = await CacheService.getGlobal();
      expect(globalVersion, null);

      final channel = await CacheService.getByVersionName(_channel);
      final version = await CacheService.getByVersionName(_version);
      // Set channel as global
      CacheService.setGlobal(channel!);
      globalVersion = await CacheService.getGlobal();
      isChanneGlobal = await CacheService.isGlobal(channel);
      isVersionGlobal = await CacheService.isGlobal(version!);

      expect(globalVersion!.name, channel.name);
      expect(isChanneGlobal, true);
      expect(isVersionGlobal, false);

      // Set version as global
      CacheService.setGlobal(version);
      globalVersion = await CacheService.getGlobal();
      isChanneGlobal = await CacheService.isGlobal(channel);
      isVersionGlobal = await CacheService.isGlobal(version);

      expect(globalVersion!.name, version.name);
      expect(isChanneGlobal, false);
      expect(isVersionGlobal, true);
    });
  });
}
