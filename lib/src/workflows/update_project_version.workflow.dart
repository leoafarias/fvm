import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/utils/logger.dart';

/// Pin version to the project
void updateSdkVersionWorkflow(
  Project project,
  String sdkVersion, {
  String? flavor,
}) {
  logger
    ..detail('')
    ..detail('Updating project config')
    ..detail('Project name: ${project.name}')
    ..detail('Project path: ${project.path}')
    ..detail('');

  try {
    final newConfig = project.config ?? ConfigDto.empty();
    // Attach as main version if no flavor is set
    final flutterSdkVersoin = sdkVersion;
    final flavors = newConfig.flavors ?? {};
    if (flavor != null) {
      flavors[flavor] = sdkVersion;
    }

    final mergedConfig = newConfig.copyWith(
      flutterSdkVersion: flutterSdkVersoin,
      flavors: flavors,
    );

    ConfigRepository(project.configPath).save(mergedConfig);

    // Clean this up
    project.config = mergedConfig;
    print(project);
  } on Exception {
    logger.fail('Failed to update project config');
    rethrow;
  }

  try {
    ProjectService.instance.updateFlutterSdkReference(project);
    ProjectService.instance.updateVsCodeConfig(project);
    logger.detail('Project config updated');
  } on Exception {
    logger.fail('Failed to update project references');
    rethrow;
  }

  ProjectService.instance.addToGitignore(project, '.fvm/versions');
}
