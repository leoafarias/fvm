import 'package:args/args.dart';
import 'package:meta/meta.dart';

import '../services/cache_service.dart';
import '../services/project_service.dart';
import '../utils/context.dart';
import '../utils/exceptions.dart';
import '../workflows/run_configured_flutter.workflow.dart';
import '../workflows/validate_flutter_version.workflow.dart';
import 'base_command.dart';

/// Proxies Flutter Commands
class FlutterCommand extends BaseFvmCommand {
  @override
  final name = 'flutter';
  @override
  final description =
      'Runs Flutter commands using the project\'s configured SDK version';
  @override
  final argParser = ArgParser.allowAnything();

  FlutterCommand(super.context);

  @override
  Future<int> run() async {
    final args = argResults!.arguments;
    checkIfUpgradeCommand(context, args);
    final runConfiguredFlutterWorkflow = RunConfiguredFlutterWorkflow(context);

    final result = await runConfiguredFlutterWorkflow('flutter', args: args);

    return result.exitCode;
  }
}

@visibleForTesting
void checkIfUpgradeCommand(FvmContext context, List<String> args) {
  if (args.isEmpty || args.first != 'upgrade') return;

  // Get current version - project version has priority, then global
  final projectVersionName = context.get<ProjectService>().findVersion();
  final versionToCheck =
      projectVersionName ?? context.get<CacheService>().getGlobal()?.name;

  if (versionToCheck != null) {
    final version = context.get<ValidateFlutterVersionWorkflow>().call(
          versionToCheck,
        );

    // Only block upgrade for release versions, not channels
    if (!version.isChannel) {
      throw AppException(
        'You should not upgrade a release version. '
        'Please install a channel instead to upgrade it. ',
      );
    }
  }
}
