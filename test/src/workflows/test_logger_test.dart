import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';
import 'test_logger.dart';

void main() {
  group('TestLogger', () {
    test('should override confirm method correctly', () {
      final context = TestFactory.context(
        generators: {
          Logger: (context) =>
              TestLogger(context)..setConfirmResponse('test prompt', true),
        },
        skipInput: false, // Allow user input for testing
      );

      final logger = context.get<Logger>();

      final result =
          logger.confirm('This is a test prompt', defaultValue: false);

      expect(result, isTrue);
      expect(
        logger.outputs.any((msg) => msg.contains('This is a test prompt')),
        isTrue,
      );
      expect(
        logger.outputs.any((msg) => msg.contains('User response: Yes')),
        isTrue,
      );
    });

    test('should override select method correctly', () {
      final context = TestFactory.context(
        generators: {
          Logger: (context) =>
              TestLogger(context)..setSelectResponse('choose option', 1),
        },
        skipInput: false, // Allow user input for testing
      );

      final logger = context.get<Logger>();

      final result = logger.select(
        'Please choose option',
        options: ['Option A', 'Option B', 'Option C'],
      );

      expect(result, 'Option B');
      expect(
        logger.outputs.any((msg) => msg.contains('Please choose option')),
        isTrue,
      );
      expect(
        logger.outputs.any((msg) => msg.contains('User selected: Option B')),
        isTrue,
      );
    });

    test('should override cacheVersionSelector method correctly', () {
      final context = TestFactory.context(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setVersionResponse('Select a version', '3.10.0'),
        },
        skipInput: false, // Allow user input for testing
      );

      final logger = context.get<Logger>();

      final versions = [
        CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('3.10.0'),
          directory: '/test/3.10.0',
        ),
        CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('3.11.0'),
          directory: '/test/3.11.0',
        ),
      ];

      final result = logger.cacheVersionSelector(versions);

      expect(result, '3.10.0');
      expect(
        logger.outputs.any((msg) => msg.contains('Select a version')),
        isTrue,
      );
      expect(
        logger.outputs
            .any((msg) => msg.contains('User selected version: 3.10.0')),
        isTrue,
      );
    });

    test('should fall back to parent behavior when no response is set', () {
      final context = TestFactory.context(
        generators: {
          Logger: (context) => TestLogger(context),
          // No responses set
        },
        skipInput: true, // This will cause parent to return default value
      );

      final logger = context.get<Logger>();

      final result = logger.confirm('Unmatched prompt', defaultValue: false);

      expect(result, isFalse);
      expect(
        logger.outputs.any((msg) => msg.contains('Unmatched prompt')),
        isTrue,
      );
      expect(
        logger.outputs
            .any((msg) => msg.contains('Skipping input confirmation')),
        isTrue,
      );
    });
  });
}
