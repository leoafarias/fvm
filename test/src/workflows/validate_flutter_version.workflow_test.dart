import 'package:fvm/src/workflows/validate_flutter_version.workflow.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('ValidateFlutterVersionWorkflow', () {
    /// Valid release version
    test('should return valid release version', () async {
      const version = '3.10.0';

      final context = TestFactory.context();

      final workflow = ValidateFlutterVersionWorkflow(context);

      final result = workflow.call(version);

      expect(result.isRelease, isTrue);
      expect(result.name, equals(version));
    });

    /// Invalid version
    test('should return invalid version as unknownRef', () async {
      const version = 'invalid-version';

      final context = TestFactory.context();

      final workflow = ValidateFlutterVersionWorkflow(context);

      final result = workflow.call(version);

      expect(result.isUnknownRef, isTrue);
      expect(result.name, equals(version));
    });

    /// Channel
    test('should return channel version', () async {
      const version = 'stable';

      final context = TestFactory.context();

      final workflow = ValidateFlutterVersionWorkflow(context);

      final result = workflow.call(version);

      expect(result.isChannel, isTrue);
      expect(result.name, equals(version));
    });

    /// Commit

    test('should skip validation when force flag is true', () async {
      // Arrange
      const version = 'invalid-version';

      final context = TestFactory.context();

      final workflow = ValidateFlutterVersionWorkflow(context);

      // Act
      final result = workflow.call(version);

      // Assert
      expect(result.isUnknownRef, isTrue);
      expect(result.name, equals(version));
    });
  });
}
