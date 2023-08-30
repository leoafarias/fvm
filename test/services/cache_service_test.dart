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
    test('Cache Version', () async {
      var validChannel = await CacheService.getVersionCache(
        ValidVersion(_channel),
      );
      var validVersion = await CacheService.getVersionCache(
        ValidVersion(_version),
      );
      expect(validChannel, null);
      expect(validVersion, null);

      print('Cache channel');

      await CacheService.cacheVersion(ValidVersion(_channel));

      print('Cache version');
      await CacheService.cacheVersion(ValidVersion(_version));

      validChannel = await CacheService.getVersionCache(ValidVersion(_channel));
      validVersion = await CacheService.getVersionCache(ValidVersion(_version));
      expect(validChannel!.name, _channel);
      expect(validVersion!.name, _version);

      final versions = await CacheService.getAllVersions();
      expect(versions.length, 2);

      expect(validChannel.name, _channel);
      expect(validVersion.name, _version);

      final invalidCache = CacheVersion('invalid_version');

      expect(validChannel.isValidCache, true);
      expect(validVersion.isValidCache, true);
      expect(invalidCache.isValidCache, false);
    });

    // TODO: Remove after deprecation period

    // testWithContext('Set/Get Global Cache Version ', key, () async {
    //   CacheVersion? globalVersion;
    //   bool isChanneGlobal, isVersionGlobal;
    //   globalVersion = await CacheService.getGlobal();
    //   expect(globalVersion, null);

    //   final channel = await CacheService.getByVersionName(_channel);
    //   final version = await CacheService.getByVersionName(_version);
    //   // Set channel as global
    //   await CacheService.setGlobal(channel!);
    //   globalVersion = await CacheService.getGlobal();
    //   isChanneGlobal = await CacheService.isGlobal(channel);
    //   isVersionGlobal = await CacheService.isGlobal(version!);

    //   expect(globalVersion!.name, channel.name);
    //   expect(isChanneGlobal, true);
    //   expect(isVersionGlobal, false);

    //   // Set version as global
    //   await CacheService.setGlobal(version);
    //   globalVersion = await CacheService.getGlobal();
    //   isChanneGlobal = await CacheService.isGlobal(channel);
    //   isVersionGlobal = await CacheService.isGlobal(version);

    //   expect(globalVersion!.name, version.name);
    //   expect(isChanneGlobal, false);
    //   expect(isVersionGlobal, true);
    // });
  });
}
