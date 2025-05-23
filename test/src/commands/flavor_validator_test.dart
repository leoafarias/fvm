import 'package:args/command_runner.dart';
import 'package:fvm/src/commands/use_command.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('Flavor name validator:', () {
    late TestCommandRunner runner;
    late UseCommand useCommand;

    setUp(() {
      runner = TestFactory.commandRunner();
      useCommand = runner.commands['use']! as UseCommand;
    });

    void testValidateFlavorName(String flavorName, {required bool shouldFail}) {
      validator(String name) => useCommand.validateFlavorNameForTesting(name);

      if (shouldFail) {
        expect(() => validator(flavorName), throwsA(isA<UsageException>()));
      } else {
        expect(() => validator(flavorName), returnsNormally);
      }
    }

    test('rejects Flutter channel names', () {
      testValidateFlavorName('stable', shouldFail: true);
      testValidateFlavorName('beta', shouldFail: true);
      testValidateFlavorName('dev', shouldFail: true);
      testValidateFlavorName('master', shouldFail: true);
    });

    test('rejects semver versions', () {
      testValidateFlavorName('1.0.0', shouldFail: true);
      testValidateFlavorName('3.10.5', shouldFail: true);
      testValidateFlavorName('1.2.3-beta', shouldFail: true);
    });

    test('rejects git commit hashes', () {
      testValidateFlavorName('abcdef1234567890', shouldFail: true);
      testValidateFlavorName('123456789', shouldFail: true);
    });

    test('rejects invalid characters', () {
      testValidateFlavorName('prod@env', shouldFail: true);
      testValidateFlavorName('prod space', shouldFail: true);
      testValidateFlavorName('prod.env', shouldFail: true);
      testValidateFlavorName('prod/env', shouldFail: true);
    });

    test('rejects flavor names starting with numbers', () {
      testValidateFlavorName('1prod', shouldFail: true);
      testValidateFlavorName('123env', shouldFail: true);
    });

    test('rejects reserved words', () {
      testValidateFlavorName('flutter', shouldFail: true);
      testValidateFlavorName('version', shouldFail: true);
      testValidateFlavorName('cache', shouldFail: true);
      testValidateFlavorName('FVM', shouldFail: true); // Case insensitive check
    });

    test('accepts valid flavor names', () {
      testValidateFlavorName('prod', shouldFail: false);
      testValidateFlavorName('staging', shouldFail: false);
      testValidateFlavorName('development', shouldFail: false);
      testValidateFlavorName('prod_env', shouldFail: false);
      testValidateFlavorName('staging-env', shouldFail: false);
      testValidateFlavorName('myApp', shouldFail: false);
    });
  });
}
