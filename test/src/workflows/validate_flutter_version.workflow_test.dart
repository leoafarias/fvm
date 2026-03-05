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

    /// Git reference
    test('should return unknownRef for non-semver input', () async {
      const version = 'some-commit-ref';

      final context = TestFactory.context();

      final workflow = ValidateFlutterVersionWorkflow(context);

      final result = workflow.call(version);

      expect(result.isUnknownRef, isTrue);
      expect(result.name, equals(version));
    });

    /// Slash ref vs fork alias ambiguity
    test('should treat slash ref as git reference when fork not configured',
        () async {
      const version = 'feature/my-branch';

      final context = TestFactory.context();

      final workflow = ValidateFlutterVersionWorkflow(context);

      final result = workflow.call(version);

      // Should fall back to git reference (no fork prefix)
      expect(result.isUnknownRef, isTrue);
      expect(result.fromFork, isFalse);
      expect(result.name, equals(version));
    });

    test('should error for slash channel when fork not configured', () async {
      const version = 'myfork/stable';

      final context = TestFactory.context();

      final workflow = ValidateFlutterVersionWorkflow(context);

      expect(
        () => workflow.call(version),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains(
                  'Fork "myfork" has not been configured',
                ),
          ),
        ),
      );
    });

    test('should error for slash release when fork not configured', () async {
      const version = 'myfork/3.24.0';

      final context = TestFactory.context();

      final workflow = ValidateFlutterVersionWorkflow(context);

      expect(
        () => workflow.call(version),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains(
                  'Fork "myfork" has not been configured',
                ),
          ),
        ),
      );
    });
  });
}
