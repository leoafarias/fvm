import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/utils/pretty_json.dart';

/// Pin version to the project
void updateSdkVersionWorkflow(
  Project project,
  String sdkVersion, {
  String? flavor,
}) {
  logger
    ..detail('Updating project config')
    ..detail('Project name: ${project.name}')
    ..detail('Project path: ${project.projectDir.path}');

  try {
    final newConfig = project.config ?? ProjectConfig.empty();
    // Attach as main version if no flavor is set
    newConfig.flutter = sdkVersion;
    if (flavor != null) {
      newConfig.flavors ??= {};
      newConfig.flavors![flavor] = sdkVersion;
    }

    if (!project.configFile.existsSync()) {
      project.configFile.createSync(recursive: true);
    }

    project.configFile.writeAsStringSync(
      prettyJson(newConfig.toMap()),
    );

    // Clean this up
    project.config = newConfig;
  } on Exception catch (err) {
    logger.err('Failed to update project config');
    throw FvmError(err.toString());
  }

  try {
    ProjectService.instance.updateFlutterSdkReference(project);
    ProjectService.instance.updateVsCodeConfig(project);
    logger.detail('Project config updated');
  } on Exception {
    logger.err('Failed to update SDK links');
    rethrow;
  }
  ProjectService.instance.addToGitignore(project, '.fvm/versions');
}
