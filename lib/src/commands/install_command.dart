import 'dart:async';

import 'package:io/io.dart';

import '../services/project_service.dart';
import '../utils/exceptions.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/setup_flutter.workflow.dart';
import '../workflows/use_version.workflow.dart';
import '../workflows/validate_flutter_version.workflow.dart';
import 'base_command.dart';

/// Installs Flutter SDK
class InstallCommand extends BaseFvmCommand {
  @override
  final name = 'install';

  @override
  final description =
      'Installs a Flutter SDK version and caches it for future use';

  /// Constructor
  InstallCommand(super.context) {
    argParser
      ..addFlag(
        'skip-setup',
        help: 'Skip downloading SDK dependencies after install',
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
    final skipSetup = boolArg('skip-setup');
    final skipPubGet = boolArg('skip-pub-get');
    String? version;

    final ensureCache = EnsureCacheWorkflow(context);
    final useVersion = UseVersionWorkflow(context);
    final setupFlutter = SetupFlutterWorkflow(context);
    final validateFlutterVersion = ValidateFlutterVersionWorkflow(context);

    // If no version was passed as argument check project config.
    if (argResults!.rest.isEmpty) {
      final project = get<ProjectService>().findAncestor();

      final version = project.pinnedVersion;

      // If no config found is version throw error
      if (version == null) {
        throw const AppException(
          'Please provide a channel or a version, or run'
          ' this command in a Flutter project that has FVM configured.',
        );
      }

      final cacheVersion = await ensureCache(version, shouldInstall: true);

      await useVersion(
        version: cacheVersion,
        project: project,
        force: true,
        skipSetup: skipSetup,
        skipPubGet: skipPubGet,
      );

      return ExitCode.success.code;
    }
    version ??= argResults!.rest[0];

    final flutterVersion = validateFlutterVersion(version);

    final cacheVersion = await ensureCache(flutterVersion, shouldInstall: true);

    if (!skipSetup) {
      await setupFlutter(cacheVersion);
    }

    return ExitCode.success.code;
  }

  @override
  String get invocation => 'fvm install {version}, if no {version}'
      ' is provided will install version configured in project.';

  @override
  List<String> get aliases => ['i'];
}
