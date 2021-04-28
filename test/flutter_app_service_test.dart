@Timeout(Duration(minutes: 5))
import 'package:fvm/src/services/project_service.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Flutter Projects', () {
    test('Can set SDK version on Flutter Project', () async {
      try {
        final project = await ProjectService.getByDirectory(kFlutterAppDir);

        final validVersion = await getRandomFlutterVersion();

        await ProjectService.pinVersion(
          project,
          validVersion,
        );

        expect(project.pinnedVersion, validVersion.name);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });
    test('Can find Flutter Project', () async {
      try {
        final flutterProject =
            await ProjectService.findAncestor(directory: kFlutterAppDir);
        final dartPackage =
            await ProjectService.findAncestor(directory: kDartPackageDir);
        final emptyProject =
            await ProjectService.findAncestor(directory: kEmptyDir);

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
          await ProjectService.scanDirectory(rootDir: kTestAssetsDir);
      expect(projects.length, 1);
    });
  });
}
