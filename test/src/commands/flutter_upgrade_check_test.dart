import 'package:fvm/src/commands/flutter_command.dart';
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('checkIfUpgradeCommand', () {
    test('throws for release versions', () {
      final context = TestFactory.context();
      final cacheService = context.get<CacheService>();
      final release = FlutterVersion.parse('2.0.0');
      final dir = cacheService.getVersionCacheDir(release);
      dir.createSync(recursive: true);
      final cacheVersion = CacheFlutterVersion.fromVersion(
        release,
        directory: dir.path,
      );
      cacheService.setGlobal(cacheVersion);

      expect(
        () => checkIfUpgradeCommand(context, ['upgrade']),
        throwsA(isA<AppException>()),
      );
    });

    test('allows channel versions', () {
      final context = TestFactory.context();
      final cacheService = context.get<CacheService>();
      final channel = FlutterVersion.parse('stable');
      final dir = cacheService.getVersionCacheDir(channel);
      dir.createSync(recursive: true);
      final cacheVersion = CacheFlutterVersion.fromVersion(
        channel,
        directory: dir.path,
      );
      cacheService.setGlobal(cacheVersion);

      expect(
        () => checkIfUpgradeCommand(context, ['upgrade']),
        returnsNormally,
      );
    });
  });
}
