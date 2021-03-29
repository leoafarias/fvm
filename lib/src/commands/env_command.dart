import 'package:args/command_runner.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';

import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/console_utils.dart';

import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:io/io.dart';

/// Configure different flutter version per environment
class EnvCommand extends Command<int> {
  @override
  final name = 'env';
  @override
  final description = 'Configure different flutter version per environment';

  /// Constructor
  EnvCommand();

  @override
  Future<int> run() async {
    String environment;

    if (argResults.rest.isEmpty) {
      environment = await projectEnvSeletor();
    }

    // Gets env from param if not yet selected
    environment ??= argResults.rest[0];

    final project = await FlutterAppService.findAncestor();

    // If project use check that is Flutter project
    if (project == null) {
      throw const FvmUsageException(
        'Cannot find any FVM config.',
      );
    }

    // Gets environment version
    final envs = project.config.environment;
    final envVersion = envs[environment] as String;

    // Check if env confi exists
    if (envVersion == null) {
      throw FvmUsageException('Environment: "$environment" is not configured');
    }

    // Makes sure that is a valid version
    final validVersion = await FlutterTools.inferVersion(envVersion);

    FvmLogger.spacer();

    FvmLogger.info(
      'Switching to [$environment] environment, which uses [${validVersion.version}] Flutter sdk.',
    );

    // Run install workflow
    await ensureCacheWorkflow(validVersion);

    // Pin version to project
    await FlutterAppService.pinVersion(project, validVersion);

    FvmLogger.fine(
      'Now using [$environment] environment. Flutter version [${validVersion.version}].',
    );

    FvmLogger.spacer();

    return ExitCode.success.code;
  }
}
