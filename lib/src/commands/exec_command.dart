import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../workflows/run_configured_flutter.workflow.dart';
import 'base_command.dart';

/// Executes scripts with the configured Flutter SDK
class ExecCommand extends BaseFvmCommand {
  @override
  final name = 'exec';
  @override
  final description = 'Executes scripts with the configured Flutter SDK';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  ExecCommand(super.context);

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      throw UsageException('No command was provided to be executed', usage);
    }

    final cmd = argResults!.rest[0];

    // Removes version from first arg
    final execArgs = [...?argResults?.rest]..removeAt(0);

    final runConfiguredFlutterWorkflow = RunConfiguredFlutterWorkflow(context);

    final result = await runConfiguredFlutterWorkflow(cmd, args: execArgs);

    return result.exitCode;
  }
}
