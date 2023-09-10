@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

final _channel = FlutterVersion.parse('beta');
final _version = FlutterVersion.parse('1.20.2');

void main() {
  groupWithContext('Cache Service Test:', () {
    testWithContext('Cache Version', () async {
      var validChannel = CacheService.instance.getVersion(_channel);
      var validVersion = CacheService.instance.getVersion(_version);
      expect(validChannel, null);
      expect(validVersion, null);

      await CacheService.instance.cacheVersion(_channel);
      await CacheService.instance.cacheVersion(_version);

      final cacheChannel = CacheService.instance.getVersion(_channel);

      final cacheVersion = CacheService.instance.getVersion(_version);

      final invalidVersion = CacheService.instance
          .getVersion(FlutterVersion.parse('invalid-version'));

      final channelIntegrity =
          await CacheService.instance.verifyCacheIntegrity(cacheChannel!);
      final versionIntegrity =
          await CacheService.instance.verifyCacheIntegrity(cacheVersion!);

      final versions = await CacheService.instance.getAllVersions();
      expect(versions.length, 2);

      forceUpdateFlutterSdkVersionFile(cacheVersion, '2.7.0');

      final cacheVersion2 = CacheService.instance.getVersion(_version);
      final versionIntegrity2 =
          await CacheService.instance.verifyCacheIntegrity(cacheVersion2!);

      expect(versionIntegrity, CacheIntegrity.valid);
      expect(channelIntegrity, CacheIntegrity.valid);
      expect(invalidVersion, null);
      expect(versionIntegrity2, CacheIntegrity.versionMismatch);
    });

    testWithContext('Set/Get Global Cache Version ', () async {
      CacheFlutterVersion? globalVersion;
      bool isChanneGlobal, isVersionGlobal;
      globalVersion = CacheService.instance.getGlobal();
      expect(globalVersion, null);

      final channel = CacheService.instance.getVersion(_channel);
      final version = CacheService.instance.getVersion(_version);
      // Set channel as global
      CacheService.instance.setGlobal(channel!);
      globalVersion = CacheService.instance.getGlobal();
      isChanneGlobal = CacheService.instance.isGlobal(channel);
      isVersionGlobal = CacheService.instance.isGlobal(version!);

      expect(globalVersion!.name, channel.name);
      expect(isChanneGlobal, true);
      expect(isVersionGlobal, false);

      // Set version as global
      CacheService.instance.setGlobal(version);
      globalVersion = CacheService.instance.getGlobal();
      isChanneGlobal = CacheService.instance.isGlobal(channel);
      isVersionGlobal = CacheService.instance.isGlobal(version);

      expect(globalVersion!.name, version.name);
      expect(isChanneGlobal, false);
      expect(isVersionGlobal, true);
    });
  });
}
