import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Executes a Flutter command using a specified version defined by the project flavor
class FlavorCommand extends BaseCommand {
  @override
  final name = 'flavor';
  @override
  final description =
      'Executes a Flutter command using a specified version defined by the project flavor';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  FlavorCommand(super.context);

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      throw UsageException(
        'A flavor must be specified to execute the Flutter command',
        usage,
      );
    }

    final project = controller.project.findAncestor();

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
      final cacheVersion = await ensureCacheWorkflow(
        version,
        controller: controller,
      );
      // Runs flutter command with pinned version
      logger
          .info('Using Flutter version "$version" for the "$flavor" flavor...');

      final results = await controller.flutter.runFlutter(
        flutterArgs,
        version: cacheVersion,
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
