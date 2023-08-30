import 'package:args/command_runner.dart';
import 'package:io/io.dart';

import '../models/valid_version_model.dart';
import '../services/project_service.dart';
import '../utils/console_utils.dart';
import '../utils/logger.dart';
import '../workflows/ensure_cache.workflow.dart';
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
  FlavorCommand();

  @override
  Future<int> run() async {
    String? flavor;
    final project = await ProjectService.findAncestor();

    // If project use check that is Flutter project
    if (project.config.exists == false) {
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
    final envs = project.config.flavors;
    final envVersion = envs[flavor] as String?;

    // Check if env confi exists
    if (envVersion == null) {
      throw UsageException(
        'Flavor: "$flavor" is not configured',
        'Make sure $flavor exists within the configuration',
      );
    }

    // Makes sure that is a valid version
    final validVersion = ValidVersion(envVersion);

    logger.info(
      'Switching to [$flavor] flavor, '
      'which uses [${validVersion.name}] Flutter sdk.',
    );

    // Run install workflow
    await ensureCacheWorkflow(validVersion);

    // Pin version to project
    await ProjectService.pinVersion(project, validVersion);

    logger
      ..success(
        'Now using [$flavor] flavor. '
        'Flutter version [${validVersion.name}].',
      )
      ..info('');

    return ExitCode.success.code;
  }
}
