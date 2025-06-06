import 'package:args/args.dart';

import '../models/flutter_version_model.dart';
import '../services/cache_service.dart';
import '../services/project_service.dart';
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

  void _checkIfUpgradeCommand(List<String> args) {
    // Only check if the first argument is 'upgrade'
    if (args.isEmpty || args.first != 'upgrade') {
      return;
    }

    // Get the current version being used (project takes priority over global)
    FlutterVersion? currentVersion;

    final projectVersion = get<ProjectService>().findVersion();
    if (projectVersion != null) {
      currentVersion =
          get<ValidateFlutterVersionWorkflow>().call(projectVersion);
    } else {
      final globalVersion = get<CacheService>().getGlobal();
      if (globalVersion != null) {
        currentVersion = globalVersion;
      }
    }

    // Only block upgrade if we have a non-channel version (release or custom)
    if (currentVersion != null && !currentVersion.isChannel) {
      throw AppException(
        'You should not upgrade a ${currentVersion.isRelease ? "release" : "custom"} version. '
        'Please install a channel instead to upgrade it. ',
      );
    }
    // If it's a channel, no version configured, or any other case, allow the upgrade
  }

  @override
  Future<int> run() async {
    final args = argResults!.arguments;
    _checkIfUpgradeCommand(args);
    final runConfiguredFlutterWorkflow = RunConfiguredFlutterWorkflow(context);

    final result = await runConfiguredFlutterWorkflow('flutter', args: args);

    return result.exitCode;
  }
}
