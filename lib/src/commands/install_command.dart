import 'dart:async';

import 'package:io/io.dart';

import '../utils/exceptions.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/setup_flutter.workflow.dart';
import '../workflows/use_version.workflow.dart';
import 'base_command.dart';

/// Installs Flutter SDK
class InstallCommand extends BaseCommand {
  @override
  final name = 'install';

  @override
  final description = 'Installs Flutter SDK Version';

  /// Constructor
  InstallCommand(super.controller) {
    argParser
      ..addFlag(
        'setup',
        abbr: 's',
        help: 'Builds SDK after install',
        defaultsTo: false,
        negatable: false,
      )
      ..addFlag(
        'skip-pub-get',
        help: 'Skip resolving dependencies after switching Flutter SDK',
        defaultsTo: false,
        negatable: false,
      );
  }

  @override
  Future<int> run() async {
    final setup = boolArg('setup');
    final skipPubGet = boolArg('skip-pub-get');
    String? version;

    // If no version was passed as argument check project config.
    if (argResults!.rest.isEmpty) {
      final project = controller.project.findAncestor();

      final version = project.pinnedVersion;

      // If no config found is version throw error
      if (version == null) {
        throw const AppException(
          'Please provide a channel or a version, or run'
          ' this command in a Flutter project that has FVM configured.',
        );
      }

      final cacheVersion = await ensureCacheWorkflow(
        version.name,
        shouldInstall: true,
        controller: controller,
      );

      await useVersionWorkflow(
        version: cacheVersion,
        project: project,
        force: true,
        skipSetup: !setup,
        runPubGetOnSdkChange: !skipPubGet,
        controller: controller,
      );

      return ExitCode.success.code;
    }
    version ??= argResults!.rest[0];

    final cacheVersion = await ensureCacheWorkflow(
      version,
      shouldInstall: true,
      controller: controller,
    );

    if (setup) {
      await setupFlutterWorkflow(cacheVersion, controller: controller);
    }

    return ExitCode.success.code;
  }

  @override
  String get invocation => 'fvm install {version}, if no {version}'
      ' is provided will install version configured in project.';

  @override
  List<String> get aliases => ['i'];
}
