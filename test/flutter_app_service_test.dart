@Timeout(Duration(minutes: 5))
import 'package:fvm/src/services/project_service.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  groupWithContext('Flutter Projects', () {
    setUpAll(() => prepareLocalProjects());
    testWithContext('Can set SDK version on Flutter Project', () async {
      try {
        final project = await ProjectService.loadByDirectory(
            getTempTestDirectory('flutter_app'));

        final validVersion = await getRandomFlutterVersion();

        ProjectService.updateSdkVersion(project, validVersion.name);
        expect(project.pinnedVersion, validVersion.name);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });
    testWithContext('Can find Flutter Project', () async {
      try {
        final flutterProject = await ProjectService.findAncestor(
            directory: getTempTestDirectory('flutter_app'));
        final dartPackage = await ProjectService.findAncestor(
            directory: getTempTestDirectory('dart_package'));
        final emptyProject = await ProjectService.findAncestor(
            directory: getTempTestDirectory('empty_folder'));

        expect(flutterProject.name, 'flutter_app');
        expect(flutterProject.projectDir.path,
            getTempTestDirectory('flutter_app').path);

        expect(flutterProject.isFlutter, true);
        expect(dartPackage.isFlutter, false);
        expect(emptyProject.isFlutter, false);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });
  });
}
