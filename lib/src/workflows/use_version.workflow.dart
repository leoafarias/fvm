import 'dart:async';

import 'package:io/ansi.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../utils/helpers.dart';
import '../utils/which.dart';
import 'resolve_project_deps.workflow.dart';
import 'setup_flutter.workflow.dart';
import 'setup_gitignore.workflow.dart';
import 'update_melos_settings.workflow.dart';
import 'update_project_references.workflow.dart';
import 'update_vscode_settings.workflow.dart';
import 'verify_project.workflow.dart';
import 'workflow.dart';

class UseVersionWorkflow extends Workflow {
  const UseVersionWorkflow(super.context);

  Future<void> call({
    required CacheFlutterVersion version,
    required Project project,
    bool force = false,
    bool skipSetup = false,
    bool skipPubGet = false,
    String? flavor,
  }) async {
    if (!skipSetup) {
      await get<SetupFlutterWorkflow>()(version);
    }

    get<VerifyProjectWorkflow>()(project, force: force);

    final updatedProject = await get<UpdateProjectReferencesWorkflow>()(
      project,
      version,
      flavor: flavor,
      force: force,
    );

    get<SetupGitIgnoreWorkflow>()(project);

    if (!skipPubGet) {
      await get<ResolveProjectDependenciesWorkflow>()(
        updatedProject,
        version,
        force: force,
      );
    }

    await get<UpdateVsCodeSettingsWorkflow>()(updatedProject);

    await get<UpdateMelosSettingsWorkflow>()(updatedProject);

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
      logger.debug('Flutter SDK is already in your PATH');

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
