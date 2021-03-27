import 'package:fvm/src/services/flutter_app_service.dart';
@Timeout(Duration(minutes: 5))
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(fvmSetUpAll);
  tearDownAll(fvmTearDownAll);
  group('Flutter Projects', () {
    test('Can set SDK version on Flutter Project', () async {
      try {
        final flutterProject =
            await FlutterAppService.getByDirectory(kFlutterAppDir);

        final flutterProjectVersion = await getRandomFlutterVersion();

        await FlutterAppService.pinVersion(
          flutterProject,
          flutterProjectVersion,
        );

        expect(flutterProject.pinnedVersion, flutterProjectVersion);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });
    test('Can find Flutter Project', () async {
      try {
        final flutterProject =
            await FlutterAppService.findAncestor(dir: kFlutterAppDir);
        final dartPackage =
            await FlutterAppService.findAncestor(dir: kDartPackageDir);
        final emptyProject =
            await FlutterAppService.findAncestor(dir: kEmptyDir);

        expect(dartPackage != null, true);
        expect(emptyProject != null, true);
        expect(flutterProject != null, true);
        expect(flutterProject.name, 'flutter_app');
        expect(flutterProject.projectDir.path, kFlutterAppDir.path);

        expect(flutterProject.isFlutterProject, true);
        expect(dartPackage.isFlutterProject, false);
        expect(emptyProject.isFlutterProject, false);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Can find Flutter Project', () async {
      final projects =
          await FlutterAppService.scanDirectory(rootDir: kTestAssetsDir);
      expect(projects.length, 1);
    });
  });
}
