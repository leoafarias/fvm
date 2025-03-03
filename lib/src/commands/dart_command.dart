import 'package:args/args.dart';

import '../workflows/run_configured_flutter.workflow.dart';
import 'base_command.dart';

/// Proxies Dart Commands
class DartCommand extends BaseFvmCommand {
  @override
  final name = 'dart';
  @override
  final description = 'Proxies Dart Commands';
  @override
  final argParser = ArgParser.allowAnything();

  DartCommand(super.context);

  @override
  Future<int> run() async {
    final args = argResults!.arguments;

    final runConfiguredFlutterWorkflow = RunConfiguredFlutterWorkflow(context);

    final result = await runConfiguredFlutterWorkflow('dart', args: args);

    return result.exitCode;
  }
}
