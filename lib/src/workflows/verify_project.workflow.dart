import '../models/project_model.dart';
import '../utils/constants.dart';
import 'workflow.dart';

class VerifyProjectWorkflow extends Workflow {
  VerifyProjectWorkflow(super.context);

  /// Verifies if the project is valid or if force mode is enabled
  bool call(Project project, {required bool force}) {
    if (project.hasPubspec || force) {
      return true;
    }

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

      return true;
    }

    logger
      ..lineBreak()
      ..info('No pubspec.yaml detected in this directory');

    return logger.confirm('Would you like to continue?', defaultValue: true);
  }
}
