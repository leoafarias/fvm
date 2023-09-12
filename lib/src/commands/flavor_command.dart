import 'package:args/command_runner.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:fvm/src/workflows/use_version.workflow.dart';
import 'package:io/io.dart';

import '../models/flutter_version_model.dart';
import '../services/project_service.dart';
import '../utils/console_utils.dart';
import '../utils/logger.dart';
import 'base_command.dart';

/// Configure different flutter version per flavor
class FlavorCommand extends BaseCommand {
  @override
  final name = 'flavor';
  @override
  final description = 'Switches between different project flavors';

  @override
  final invocation = 'fvm flavor {flavor_name}';

  @override
  final aliases = ['env', 'environment'];

  /// Constructor
  FlavorCommand() {
    argParser
      ..addFlag(
        'skip-setup',
        help: 'Skips Flutter setup after install',
        negatable: false,
      )
      ..addOption(
        'force',
        help: 'Skips command guards that does Flutter project checks.',
        abbr: 'f',
      );
  }

  @override
  Future<int> run() async {
    String? flavor;
    final project = await ProjectService.instance.findAncestor();

    // If project use check that is Flutter project
    if (project.hasConfig == false) {
      logger.info('Cannot find any FVM config in project.');
      return ExitCode.success.code;
    }
    if (argResults!.rest.isEmpty) {
      flavor = await projectFlavorSelector(project);
      if (flavor == null) {
        logger.info('No flavors configured in the project');
        return ExitCode.success.code;
      }
    }

    // Gets env from param if not yet selected
    flavor ??= argResults!.rest[0];

    // Gets flavor version
    final envs = project.flavors;
    final envVersion = envs[flavor] as String?;

    // Check if env config exists
    if (envVersion == null) {
      throw UsageException(
        'Flavor: "$flavor" is not configured',
        'Make sure $flavor exists within the configuration',
      );
    }

    // Makes sure that is a valid version
    final validVersion = FlutterVersion.parse(envVersion);

    logger.info(
      'Switching to [$flavor] flavor, '
      'which uses [${validVersion.name}] Flutter sdk.',
    );

    final cacheVersion = await ensureCacheWorkflow(validVersion);

    await useVersionWorkflow(
      version: cacheVersion,
      project: project,
      flavor: flavor,
    );

    logger
      ..complete('Now using [$flavor] flavor.')
      ..spacer;

    return ExitCode.success.code;
  }
}
