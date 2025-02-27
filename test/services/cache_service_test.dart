@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

final _channel = FlutterVersion.parse('beta');
final _version = FlutterVersion.parse('1.20.2');

void main() {
  groupWithContext('Cache Service Test:', () {
    testWithContext('Cache Version', () async {
      var validChannel = ctx.cacheService.getVersion(_channel);
      var validVersion = ctx.cacheService.getVersion(_version);
      expect(validChannel, null);
      expect(validVersion, null);

      await ctx.flutterService.install(_channel, useGitCache: true);
      await ctx.flutterService.install(_version, useGitCache: true);

      final cacheChannel = ctx.cacheService.getVersion(_channel);

      final cacheVersion = ctx.cacheService.getVersion(_version);

      final invalidVersion = ctx.cacheService.getVersion(
        FlutterVersion.parse('invalid-version'),
      );

      final channelIntegrity =
          await ctx.cacheService.verifyCacheIntegrity(cacheChannel!);
      final versionIntegrity =
          await ctx.cacheService.verifyCacheIntegrity(cacheVersion!);

      final versions = await ctx.cacheService.getAllVersions();
      expect(versions.length, 2);

      forceUpdateFlutterSdkVersionFile(cacheVersion, '2.7.0');

      final cacheVersion2 = ctx.cacheService.getVersion(_version);
      final versionIntegrity2 =
          await ctx.cacheService.verifyCacheIntegrity(cacheVersion2!);

      expect(versionIntegrity, CacheIntegrity.valid);
      expect(channelIntegrity, CacheIntegrity.valid);
      expect(invalidVersion, null);
      expect(versionIntegrity2, CacheIntegrity.versionMismatch);
    });

    testWithContext('Set/Get Global Cache Version ', () async {
      CacheFlutterVersion? globalVersion;
      bool isChanneGlobal, isVersionGlobal;
      globalVersion = ctx.globalVersionService.getGlobal();
      expect(globalVersion, null);

      final channel = ctx.cacheService.getVersion(_channel);
      final version = ctx.cacheService.getVersion(_version);
      // Set channel as global
      ctx.globalVersionService.setGlobal(channel!);
      globalVersion = ctx.globalVersionService.getGlobal();
      isChanneGlobal = ctx.globalVersionService.isGlobal(channel);
      isVersionGlobal = ctx.globalVersionService.isGlobal(version!);

      expect(globalVersion?.name, channel.name);
      expect(isChanneGlobal, true);
      expect(isVersionGlobal, false);

      // Set version as global
      ctx.globalVersionService.setGlobal(version);
      globalVersion = ctx.globalVersionService.getGlobal();
      isChanneGlobal = ctx.globalVersionService.isGlobal(channel);
      isVersionGlobal = ctx.globalVersionService.isGlobal(version);

      expect(globalVersion?.name, version.name);
      expect(isChanneGlobal, false);
      expect(isVersionGlobal, true);
    });
  });
}
