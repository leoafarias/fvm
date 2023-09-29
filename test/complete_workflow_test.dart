@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  groupWithContext('Complete flow', () {
    final runner = TestCommandRunner();

    testWithContext('Full project workflow', () async {
      await runner.run('fvm install $channel');

      Future<CacheFlutterVersion?> getCacheVersion() async {
        return CacheService.fromContext.getVersion(
          FlutterVersion.parse(channel),
        );
      }

      var cacheVersion = await getCacheVersion();

      final existingChannel = await getBranch(channel);

      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingChannel, channel);

      expect(
        cacheVersion?.notSetup,
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

      var project = ProjectService.fromContext.findAncestor();

      expect(project.pinnedVersion, isNull);

      await runner.run('fvm use $channel --skip-setup');

      project = ProjectService.fromContext.findAncestor();

      cacheVersion = await getCacheVersion();

      expect(project.pinnedVersion?.name, channel);

      expect(
        cacheVersion?.notSetup,
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
