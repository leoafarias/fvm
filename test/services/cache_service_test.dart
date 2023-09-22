@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/global_version_service.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

final _channel = FlutterVersion.parse('beta');
final _version = FlutterVersion.parse('1.20.2');

void main() {
  groupWithContext('Cache Service Test:', () {
    testWithContext('Cache Version', () async {
      var validChannel = CacheService.fromContext.getVersion(_channel);
      var validVersion = CacheService.fromContext.getVersion(_version);
      expect(validChannel, null);
      expect(validVersion, null);

      await FlutterService.fromContext.install(_channel);
      await FlutterService.fromContext.install(_version);

      final cacheChannel = CacheService.fromContext.getVersion(_channel);

      final cacheVersion = CacheService.fromContext.getVersion(_version);

      final invalidVersion = CacheService.fromContext
          .getVersion(FlutterVersion.parse('invalid-version'));

      final channelIntegrity =
          await CacheService.fromContext.verifyCacheIntegrity(cacheChannel!);
      final versionIntegrity =
          await CacheService.fromContext.verifyCacheIntegrity(cacheVersion!);

      final versions = await CacheService.fromContext.getAllVersions();
      expect(versions.length, 2);

      forceUpdateFlutterSdkVersionFile(cacheVersion, '2.7.0');

      final cacheVersion2 = CacheService.fromContext.getVersion(_version);
      final versionIntegrity2 =
          await CacheService.fromContext.verifyCacheIntegrity(cacheVersion2!);

      expect(versionIntegrity, CacheIntegrity.valid);
      expect(channelIntegrity, CacheIntegrity.valid);
      expect(invalidVersion, null);
      expect(versionIntegrity2, CacheIntegrity.versionMismatch);
    });

    testWithContext('Set/Get Global Cache Version ', () async {
      CacheFlutterVersion? globalVersion;
      bool isChanneGlobal, isVersionGlobal;
      globalVersion = GlobalVersionService.fromContext.getGlobal();
      expect(globalVersion, null);

      final channel = CacheService.fromContext.getVersion(_channel);
      final version = CacheService.fromContext.getVersion(_version);
      // Set channel as global
      GlobalVersionService.fromContext.setGlobal(channel!);
      globalVersion = GlobalVersionService.fromContext.getGlobal();
      isChanneGlobal = GlobalVersionService.fromContext.isGlobal(channel);
      isVersionGlobal = GlobalVersionService.fromContext.isGlobal(version!);

      expect(globalVersion?.name, channel.name);
      expect(isChanneGlobal, true);
      expect(isVersionGlobal, false);

      // Set version as global
      GlobalVersionService.fromContext.setGlobal(version);
      globalVersion = GlobalVersionService.fromContext.getGlobal();
      isChanneGlobal = GlobalVersionService.fromContext.isGlobal(channel);
      isVersionGlobal = GlobalVersionService.fromContext.isGlobal(version);

      expect(globalVersion?.name, version.name);
      expect(isChanneGlobal, false);
      expect(isVersionGlobal, true);
    });
  });
}
