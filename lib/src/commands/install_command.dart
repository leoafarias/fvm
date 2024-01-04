import 'dart:async';

import 'package:fvm/src/workflows/setup_flutter.workflow.dart';
import 'package:io/io.dart';

import '../../exceptions.dart';
import '../services/project_service.dart';
import '../workflows/ensure_cache.workflow.dart';
import 'base_command.dart';

/// Installs Flutter SDK
class InstallCommand extends BaseCommand {
  @override
  final name = 'install';

  @override
  final description = 'Installs Flutter SDK Version';

  /// Constructor
  InstallCommand() {
    argParser.addFlag(
      'setup',
      help: 'Builds SDK after install after install',
      abbr: 's',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final setup = boolArg('setup');
    String? version;

    // If no version was passed as argument check project config.
    if (argResults!.rest.isEmpty) {
      version = ProjectService.fromContext.findVersion();

      // If no config found is version throw error
      if (version == null) {
        throw const AppException(
          'Please provide a channel or a version, or run'
          ' this command in a Flutter project that has FVM configured.',
        );
      }
    }
    version ??= argResults!.rest[0];

    final cacheVersion = await ensureCacheWorkflow(
      version,
      shouldInstall: true,
    );

    if (setup) {
      await setupFlutterWorkflow(cacheVersion);
    }

    return ExitCode.success.code;
  }

  @override
  String get invocation => 'fvm install {version}, if no {version}'
      ' is provided will install version configured in project.';

  @override
  List<String> get aliases => ['i'];
}
