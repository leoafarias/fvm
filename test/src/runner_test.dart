import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/src/commands/api_command.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late TestCommandRunner runner;

  setUp(() {
    runner = TestFactory.fastCommandRunner();
  });

  test('API commands preserve explicit non-zero exit codes', () async {
    final apiCommand = runner.commands['api'] as APICommand;
    apiCommand.addSubcommand(_ExitCommand(42));

    final result = await runner.run(['fvm', 'api', _ExitCommand.commandName]);

    expect(result, 42);
  });

  group('TestCommandRunner.runOrThrow', () {
    test('throws when a command returns a non-zero exit code', () async {
      runner.addCommand(_ExitCommand(42));

      expect(
        () => runner.runOrThrow(['fvm', _ExitCommand.commandName]),
        throwsA(isA<ProcessException>().having(
          (error) => error.errorCode,
          'errorCode',
          42,
        )),
      );
    });

    test('requires commands to start with the fvm executable', () async {
      expect(
        () => runner.runOrThrow(['other', '--version']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

class _ExitCommand extends Command<int> {
  static const commandName = 'exit-with-code';

  final int code;

  _ExitCommand(this.code);

  @override
  String get description => 'Returns a configured exit code for testing';

  @override
  String get name => commandName;

  @override
  int run() => code;
}
