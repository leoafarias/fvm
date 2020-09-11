@Timeout(Duration(minutes: 5))

import 'package:fvm/fvm.dart';

import 'package:fvm/src/flutter_tools/git_tools.dart';

import 'package:fvm/src/local_versions/local_version.repo.dart';
import 'package:fvm/src/workflows/install_version.workflow.dart';
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
          await installWorkflow(version);
          final gitVersion = await gitGetVersion(version);
          final isInstalled = await LocalVersionRepo.isInstalled(version);
          expect(isInstalled, true);
          expect(gitVersion, version);
        } on Exception catch (e) {
          fail('Exception thrown, $e');
        }
      }

      final localVersions = await LocalVersionRepo.getAll();
      expect(localVersions.length, listVersions.length,
          reason: 'Checking if all versions were installed');
    });

    test('Remove Versions', () async {
      for (var version in listVersions) {
        try {
          await removeWorkflow(version);

          final isInstalled = await LocalVersionRepo.isInstalled(version);
          expect(isInstalled, false);
        } on Exception catch (e) {
          fail('Exception thrown, $e');
        }
      }

      final localVersions = await LocalVersionRepo.getAll();
      expect(localVersions.isEmpty, true,
          reason: 'Checking if all versions were removed');
    });
  });
}
