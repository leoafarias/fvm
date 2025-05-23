import 'dart:io';
import 'package:fvm/src/utils/context.dart';
import 'package:test/test.dart';

import '../mocks/mock_file_system.dart';
import '../testing_utils.dart';

void main() {
  late MockFileSystem mockFileSystem;
  late Directory projectDir;
  late Directory versionDir;
  late FvmContext testContext;

  setUp(() {
    mockFileSystem = MockFileSystem();

    // Create a mock project directory
    projectDir = mockFileSystem.directory('/test/project');
    projectDir.createSync(recursive: true);

    // Create mock version directory
    versionDir = mockFileSystem.directory('/test/fvm/versions/stable');
    versionDir.createSync(recursive: true);

    // Set up test context
    testContext = TestFactory.context(
      debugLabel: 'symlink_operations_test',
    );
  });

  group('Symlink operations:', () {
    test('creates symlinks correctly', () {
      // Create a .fvm directory in the project
      final fvmDir = mockFileSystem.directory('/test/project/.fvm');
      fvmDir.createSync();

      // Create a link to the Flutter SDK
      final flutterSdkLink =
          mockFileSystem.link('/test/project/.fvm/flutter_sdk');
      flutterSdkLink.createSync(versionDir.path);

      // Verify the link was created and points to the right target
      expect(flutterSdkLink.existsSync(), isTrue);
      expect(flutterSdkLink.targetSync(), equals(versionDir.path));
    });

    test('handles deletion and recreation of symlinks', () {
      // Create a .fvm directory in the project
      final fvmDir = mockFileSystem.directory('/test/project/.fvm');
      fvmDir.createSync();

      // Create an initial link
      final flutterSdkLink =
          mockFileSystem.link('/test/project/.fvm/flutter_sdk');
      flutterSdkLink.createSync('/test/fvm/versions/beta');

      // Verify the initial link
      expect(flutterSdkLink.targetSync(), equals('/test/fvm/versions/beta'));

      // Delete the link
      flutterSdkLink.deleteSync();
      expect(flutterSdkLink.existsSync(), isFalse);

      // Create a new link
      flutterSdkLink.createSync('/test/fvm/versions/stable');

      // Verify the new link
      expect(flutterSdkLink.existsSync(), isTrue);
      expect(flutterSdkLink.targetSync(), equals('/test/fvm/versions/stable'));
    });

    test('handles symlink creation failures', () {
      // Create a .fvm directory in the project
      final fvmDir = mockFileSystem.directory('/test/project/.fvm');
      fvmDir.createSync();

      // Simulate a failure during symlink creation
      mockFileSystem.simulateFailure(
        'createSync:/test/project/.fvm/flutter_sdk',
        FileSystemException('Permission denied'),
      );

      // Attempt to create the link
      final flutterSdkLink =
          mockFileSystem.link('/test/project/.fvm/flutter_sdk');
      expect(
        () => flutterSdkLink.createSync(versionDir.path),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('handles non-existent target directories', () {
      // Create a .fvm directory in the project
      final fvmDir = mockFileSystem.directory('/test/project/.fvm');
      fvmDir.createSync();

      // Create a link to a non-existent target
      final flutterSdkLink =
          mockFileSystem.link('/test/project/.fvm/flutter_sdk');
      flutterSdkLink.createSync('/test/fvm/versions/nonexistent');

      // The link exists, even though the target doesn't
      expect(flutterSdkLink.existsSync(), isTrue);
      expect(flutterSdkLink.targetSync(),
          equals('/test/fvm/versions/nonexistent'));
    });

    test('deletes existing links before creating new ones', () {
      // Create a .fvm directory in the project
      final fvmDir = mockFileSystem.directory('/test/project/.fvm');
      fvmDir.createSync();

      // Create an initial link
      final flutterSdkLink =
          mockFileSystem.link('/test/project/.fvm/flutter_sdk');
      flutterSdkLink.createSync('/test/fvm/versions/beta');

      // Verify the initial link
      expect(flutterSdkLink.targetSync(), equals('/test/fvm/versions/beta'));

      // Simulate the behavior of UpdateProjectReferencesWorkflow._updateCurrentSdkReference
      // Which deletes the existing link before creating a new one
      if (flutterSdkLink.existsSync()) {
        flutterSdkLink.deleteSync();
      }
      flutterSdkLink.createSync('/test/fvm/versions/stable');

      // Verify the new link
      expect(flutterSdkLink.existsSync(), isTrue);
      expect(flutterSdkLink.targetSync(), equals('/test/fvm/versions/stable'));
    });

    test('handles race condition during link update with mock failure', () {
      // Create a .fvm directory in the project
      final fvmDir = mockFileSystem.directory('/test/project/.fvm');
      fvmDir.createSync();

      // Create an initial link
      final flutterSdkLink =
          mockFileSystem.link('/test/project/.fvm/flutter_sdk');
      flutterSdkLink.createSync('/test/fvm/versions/beta');

      // Simulate a race condition: deletion succeeds but creation fails
      mockFileSystem.simulateFailure(
        'createSync:/test/project/.fvm/flutter_sdk',
        FileSystemException('Permission denied'),
      );

      // Attempt to perform the link update
      expect(() {
        if (flutterSdkLink.existsSync()) {
          flutterSdkLink.deleteSync();
        }
        flutterSdkLink.createSync('/test/fvm/versions/stable');
      }, throwsA(isA<FileSystemException>()));

      // The link should no longer exist
      expect(flutterSdkLink.existsSync(), isFalse);
    });
  });
}
