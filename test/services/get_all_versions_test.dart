import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late CacheService cacheService;
  late FvmContext context;
  late Directory tempDir;

  setUp(() {
    context = TestFactory.context(
      debugLabel: 'get-all-versions-test',
      privilegedAccess: true,
    );

    tempDir = Directory(context.versionsCachePath);
    cacheService = CacheService(context);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('getAllVersions', () {
    test('detects versions in both root and fork directories', () async {
      final stableVersion = FlutterVersion.parse('stable');
      final stableDir = cacheService.getVersionCacheDir(stableVersion);
      stableDir.createSync(recursive: true);
      File(path.join(stableDir.path, 'version'))
        ..createSync()
        ..writeAsStringSync('stable');
      File(path.join(stableDir.path, 'bin', 'flutter'))
          .createSync(recursive: true);

      final forkedVersion = FlutterVersion.parse('testfork/master');
      final forkedVersionDir = cacheService.getVersionCacheDir(forkedVersion);
      forkedVersionDir.createSync(recursive: true);
      File(path.join(forkedVersionDir.path, 'version'))
        ..createSync()
        ..writeAsStringSync('master');
      File(path.join(forkedVersionDir.path, 'bin', 'flutter'))
          .createSync(recursive: true);

      final versions = await cacheService.getAllVersions();

      expect(
        versions.length,
        equals(2),
        reason: 'Should find both the regular and forked versions',
      );

      final foundStableVersion = versions.firstWhere(
        (v) => v.version == 'stable',
        orElse: () => throw TestFailure('Standard version "stable" not found'),
      );
      expect(foundStableVersion.fromFork, isFalse);
      expect(foundStableVersion.directory, equals(stableDir.path));

      final foundMasterVersion = versions.firstWhere(
        (v) => v.version == 'master' && v.fromFork,
        orElse: () => throw TestFailure('Forked version "master" not found'),
      );
      expect(foundMasterVersion.fromFork, isTrue);
      expect(foundMasterVersion.fork, equals('testfork'));
      expect(foundMasterVersion.directory, equals(forkedVersionDir.path));
    });
  });
}
