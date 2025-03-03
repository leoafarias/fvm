import 'package:args/args.dart';

import '../utils/exceptions.dart';
import '../workflows/run_configured_flutter.workflow.dart';
import 'base_command.dart';

/// Proxies Flutter Commands
class FlutterCommand extends BaseFvmCommand {
  @override
  final name = 'flutter';
  @override
  final description = 'Proxies Flutter Commands';
  @override
  final argParser = ArgParser.allowAnything();

  FlutterCommand(super.context);

  @override
  Future<int> run() async {
    final args = argResults!.arguments;
    checkIfUpgradeCommand(args);
    final runConfiguredFlutterWorkflow = RunConfiguredFlutterWorkflow(context);

    final result = await runConfiguredFlutterWorkflow('flutter', args: args);

    return result.exitCode;
  }
}

void checkIfUpgradeCommand(List<String> args) {
  if (args.isNotEmpty && args.first == 'upgrade') {
    throw AppException(
      'You should not upgrade a release version. '
      'Please install a channel instead to upgrade it. ',
    );
  }
}
