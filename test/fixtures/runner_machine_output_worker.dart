import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/commands/api_command.dart';
import 'package:fvm/src/runner.dart';

Future<void> main(List<String> args) async {
  final context = FvmContext.create(
    appConfigPath: Platform.environment['FVM_TEST_APP_CONFIG']!,
    configOverrides: const AppConfig(disableUpdateCheck: true),
    workingDirectoryOverride: Directory.current.path,
    logLevel: Level.info,
    isTest: true,
  );
  final runner = FvmCommandRunner(context)
    ..environmentOverride = Platform.environment;
  final command = args.single;

  if (command == 'api') {
    final apiCommand = runner.commands['api'] as APICommand;
    apiCommand.addSubcommand(_MachineOutputCommand());
    exitCode = await runner.run(['api', _MachineOutputCommand.commandName]);
    return;
  }

  exitCode = await runner.run([HandleCompletionRequestCommand.commandName]);
}

class _MachineOutputCommand extends Command<int> {
  static const commandName = 'machine-output';

  @override
  String get description => 'Writes a JSON value for machine-output testing';

  @override
  String get name => commandName;

  @override
  int run() {
    print('{"result":"api"}');
    return 0;
  }
}
