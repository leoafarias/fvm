import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:git/git.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('GitService.resolveCommitHash', () {
    late GitService gitService;
    late CacheService cacheService;
    late FvmContext context;

    setUp(() {
      context = TestFactory.context(
        debugLabel: 'git-service-hash-test',
        privilegedAccess: true,
      );

      gitService = GitService(context);
      cacheService = CacheService(context);
    });

    test('validates resolveCommitHash method exists and is callable', () {
      // This test just verifies the method exists and can be called
      // with the correct signature
      expect(gitService.resolveCommitHash, isA<Function>());
    });

    test('returns null for non-git directory', () async {
      final version = FlutterVersion.parse('abc123');
      final versionDir = cacheService.getVersionCacheDir(version);

      // Create a non-git directory
      await Directory(versionDir.path).create(recursive: true);

      final resolved = await gitService.resolveCommitHash('abc123', version);
      expect(resolved, isNull);
    });
  });
}
