@Timeout(Duration(minutes: 5))
import 'package:test/test.dart';

import 'package:fvm/fvm.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(fvmSetUpAll);
  tearDownAll(fvmTearDownAll);
  group('Flutter Projects', () {
    test('Can find Flutter Project', () async {
      try {
        final flutterProject =
            await FlutterProjectRepo().findOne(dir: kFlutterAppDir);
        final dartPackage =
            await FlutterProjectRepo().findOne(dir: kDartPackageDir);
        final emptyProject = await FlutterProjectRepo().findOne(dir: kEmptyDir);

        expect(await flutterProject.isFlutterProject(), true);
        expect(await dartPackage.isFlutterProject(), false);
        expect(await emptyProject.isFlutterProject(), false);

        expect(flutterProject.name, 'flutter_app');
        expect(dartPackage.name, 'dart_package');

        expect(flutterProject.projectDir.path, kFlutterAppDir.path);
        expect(dartPackage.projectDir.path, kDartPackageDir.path);

        expect(emptyProject.name, null);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Can set SDK version on Flutter Project', () async {
      try {
        final flutterProject =
            await FlutterProjectRepo().findOne(dir: kFlutterAppDir);
        final dartPackage =
            await FlutterProjectRepo().findOne(dir: kDartPackageDir);
        final emptyProject = await FlutterProjectRepo().findOne(dir: kEmptyDir);

        final flutterProjectVersion = await getRandomFlutterVersion();
        final dartPackageVersion = await getRandomFlutterVersion();
        final emptyProjectVersion = await getRandomFlutterVersion();

        await flutterProject.setVersion(flutterProjectVersion);
        await dartPackage.setVersion(dartPackageVersion);
        await emptyProject.setVersion(emptyProjectVersion);

        expect(flutterProject.pinnedVersion, flutterProjectVersion);
        expect(dartPackage.pinnedVersion, dartPackageVersion);
        expect(emptyProject.pinnedVersion, emptyProjectVersion);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Can find Flutter Project', () async {
      final projects =
          await FlutterProjectRepo(rootDir: kTestAssetsDir).findAll();
      expect(projects.length, 1);
    });
  });
}
