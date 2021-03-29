@Timeout(Duration(minutes: 5))

import 'package:fvm/fvm.dart';
import 'package:fvm/src/models/valid_version_model.dart';

import 'package:fvm/src/services/git_tools.dart';

import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:fvm/src/workflows/remove_version.workflow.dart';
import 'package:test/test.dart';

import 'package:fvm/constants.dart';

import '../test_helpers.dart';

final testPath = '$kFvmHome/test_path';

const listVersions = [
  'master',
  'stable',
  'dev',
  'beta',
  '1.20.2',
  '1.17.0-dev.0.0',
  'v1.16.3'
];

void main() {
  setUpAll(fvmSetUpAll);
  tearDownAll(fvmTearDownAll);
  group('Manage Versions', () {
    test('Install Versions', () async {
      for (var version in listVersions) {
        try {
          await ensureCacheWorkflow(ValidVersion(version));
          final gitVersion = await GitTools.getBranchOrTag(version);
          final cacheVersion =
              await CacheService.isVersionCached(ValidVersion(version));
          expect(cacheVersion != null, true);
          expect(gitVersion, version);
        } on Exception catch (e) {
          fail('Exception thrown, $e');
        }
      }

      final localVersions = await CacheService.getAllVersions();
      expect(localVersions.length, listVersions.length,
          reason: 'Checking if all versions were installed');
    });

    test('Remove Versions', () async {
      for (var version in listVersions) {
        try {
          await removeWorkflow(ValidVersion(version));

          final cacheVersion =
              await CacheService.isVersionCached(ValidVersion(version));
          expect(cacheVersion == null, true);
        } on Exception catch (e) {
          fail('Exception thrown, $e');
        }
      }

      final localVersions = await CacheService.getAllVersions();
      expect(localVersions.isEmpty, true,
          reason: 'Checking if all versions were removed');
    });
  });
}
