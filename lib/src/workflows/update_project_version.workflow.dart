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
  var progress = logger.progress('Updating project config');

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

    progress.complete('Project config updated');
  } on Exception catch (err) {
    progress.fail('Failed to update project config');
    throw FvmError(err.toString());
  }
  progress = logger.progress('Updating Flutter SDK links');
  try {
    ProjectService.updateFlutterSdkReference(project);
    ProjectService.updateVsCodeConfig(project);
    progress.complete('Flutter SDK links updated');
  } on Exception {
    progress.fail('Failed to update SDK links');
    rethrow;
  }
  ProjectService.addToGitignore(project, '.fvm/versions');
}
