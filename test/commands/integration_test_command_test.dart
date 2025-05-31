import 'package:fvm/src/commands/integration_test_command.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:test/test.dart';

void main() {
  group('IntegrationTestCommand', () {
    late FvmContext context;
    late IntegrationTestCommand command;

    setUp(() {
      context = FvmContext.create(isTest: true);
      command = IntegrationTestCommand(context);
    });

    test('should be hidden from help', () {
      expect(command.hidden, isTrue);
    });

    test('should have correct name', () {
      expect(command.name, equals('integration-test'));
    });

    test('should have correct description', () {
      expect(command.description, contains('integration tests'));
    });

    test('should list phases when --list-phases flag is used', () async {
      // This is a basic test to ensure the command structure is correct
      expect(command.argParser.options.containsKey('list-phases'), isTrue);
      expect(command.argParser.options.containsKey('phase'), isTrue);
      expect(command.argParser.options.containsKey('test'), isTrue);
      expect(command.argParser.options.containsKey('fast'), isTrue);
      expect(command.argParser.options.containsKey('cleanup-only'), isTrue);
    });

    test('should create IntegrationTestRunner', () {
      final runner = IntegrationTestRunner(context);
      expect(runner, isNotNull);
      expect(runner.context, equals(context));
    });

    test('should have correct test constants', () {
      expect(IntegrationTestRunner.testChannel, equals('stable'));
      expect(IntegrationTestRunner.testRelease, equals('3.19.0'));
      expect(IntegrationTestRunner.testCommit, equals('fb57da5f94'));
      expect(IntegrationTestRunner.testForkName, equals('testfork'));
      expect(IntegrationTestRunner.testForkUrl, equals('https://github.com/flutter/flutter.git'));
    });
  });
}
