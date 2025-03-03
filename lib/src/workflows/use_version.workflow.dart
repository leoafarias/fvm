import 'dart:async';
import 'dart:io';

import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/which.dart';
import 'resolve_project_deps.workflow.dart';
import 'setup_flutter.workflow.dart';
import 'setup_gitignore.workflow.dart';
import 'update_project_references.workflow.dart';
import 'update_vscode_settings.workflow.dart';
import 'workflow.dart';

class UseVersionWorkflow extends Workflow {
  late final SetupFlutterWorkflow _setupFlutter;
  late final ResolveProjectDependenciesWorkflow _resolveProjectDependencies;
  late final SetupGitIgnoreWorkflow _setupGitIgnore;
  late final UpdateProjectReferencesWorkflow _updateProjectReferences;
  late final UpdateVsCodeSettingsWorkflow _updateVsCodeSettings;
  UseVersionWorkflow(super.context) {
    _updateProjectReferences = get<UpdateProjectReferencesWorkflow>();
    _setupGitIgnore = get<SetupGitIgnoreWorkflow>();
    _resolveProjectDependencies = get<ResolveProjectDependenciesWorkflow>();
    _setupFlutter = get<SetupFlutterWorkflow>();

    _updateVsCodeSettings = get<UpdateVsCodeSettingsWorkflow>();
  }

  Future<void> call({
    required CacheFlutterVersion version,
    required Project project,
    bool force = false,
    bool skipSetup = false,
    bool skipPubGet = false,
    String? flavor,
  }) async {
    // If project use check that is Flutter project
    if (!project.hasPubspec && !force) {
      if (project.hasConfig) {
        if (project.path != context.workingDirectory) {
          logger
            ..lineBreak()
            ..info('Using $kFvmConfigFileName in ${project.path}')
            ..lineBreak()
            ..info(
              'If this is incorrect either use the --force flag or remove the $kFvmConfigFileName and the $kFvmDirName directory.',
            )
            ..lineBreak();
        }
      } else {
        logger
          ..lineBreak()
          ..info('No pubspec.yaml detected in this directory');
        final proceed = logger.confirm(
          'Would you like to continue?',
          defaultValue: true,
        );

        if (!proceed) exit(ExitCode.success.code);
      }
    }

    logger
      ..detail('')
      ..detail('Updating project config')
      ..detail('Project name: ${project.name}')
      ..detail('Project path: ${project.path}')
      ..detail('Flutter version: ${version.name}')
      ..detail('');

    if (!skipSetup) {
      await _setupFlutter(version);
    }

    final updatedProject = await _updateProjectReferences(
      project,
      version,
      flavor: flavor,
      force: force,
    );

    await _setupGitIgnore(project, force: force);

    if (!skipPubGet) {
      await _resolveProjectDependencies(updatedProject, version, force: force);
    }

    await _updateVsCodeSettings(updatedProject);

    final versionLabel = cyan.wrap(version.printFriendlyName);
    // Different message if configured environment
    if (flavor != null) {
      logger.success(
        'Project now uses Flutter SDK: $versionLabel on [$flavor] flavor.',
      );
    } else {
      logger.success('Project now uses Flutter SDK : $versionLabel');
    }

    if (version.flutterExec == which('flutter')) {
      logger.detail('Flutter SDK is already in your PATH');

      return;
    }

    if (isVsCode()) {
      logger
        ..important(
          'Running on VsCode, please restart the terminal to apply changes.',
        )
        ..info(
          'You can then use "flutter" command within the VsCode terminal.',
        );
    }
  }
}
