import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../services/flutter_service.dart';
import '../services/project_service.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/validate_flutter_version.workflow.dart';
import 'base_command.dart';

/// Executes a Flutter command using a specified version defined by the project flavor
class FlavorCommand extends BaseFvmCommand {
  @override
  final name = 'flavor';
  @override
  final description =
      'Executes Flutter commands using the SDK version configured for a specific project flavor';
  @override
  final argParser = ArgParser.allowAnything();

  FlavorCommand(super.context);

  @override
  Future<int> run() async {
    final ensureCache = EnsureCacheWorkflow(context);
    final validateFlutterVersion = ValidateFlutterVersionWorkflow(context);

    if (argResults!.rest.isEmpty) {
      throw UsageException(
        'A flavor must be specified to execute the Flutter command',
        usage,
      );
    }

    final project = get<ProjectService>().findAncestor();

    final flavor = argResults!.rest[0];

    if (!project.flavors.containsKey(flavor)) {
      throw UsageException(
        'The specified flavor is not defined in the project configuration file',
        usage,
      );
    }

    final version = project.flavors[flavor];
    if (version != null) {
      // Removes flavor from first arg
      final flutterArgs = [...?argResults?.rest]..removeAt(0);

      // Will install version if not already installed
      final flutterVersion = validateFlutterVersion(version);
      final cacheVersion = await ensureCache(flutterVersion);
      // Runs flutter command with pinned version
      logger
          .info('Using Flutter version "$version" for the "$flavor" flavor...');

      final results = await get<FlutterService>().runFlutter(
        flutterArgs,
        cacheVersion,
      );

      return results.exitCode;
    }
    throw UsageException(
      'A version must be specified for the flavor "$flavor" in the project configuration file to execute the Flutter command',
      usage,
    );
  }

  @override
  String get invocation => 'fvm flavor {flavor}';
}
