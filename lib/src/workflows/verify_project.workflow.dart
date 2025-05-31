import '../models/project_model.dart';
import '../utils/constants.dart';
import '../utils/exceptions.dart';
import 'workflow.dart';

class VerifyProjectWorkflow extends Workflow {
  const VerifyProjectWorkflow(super.context);

  void call(Project project, {required bool force}) {
    if (project.hasPubspec || force) return;

    if (project.hasConfig && project.path != context.workingDirectory) {
      logger
        ..info()
        ..info('Using $kFvmConfigFileName in ${project.path}')
        ..info()
        ..info(
          'If this is incorrect either use --force flag or remove $kFvmConfigFileName and $kFvmDirName directory.',
        )
        ..info();

      return;
    }

    logger.info('No pubspec.yaml detected in this directory');

    if (!logger.confirm('Would you like to continue?', defaultValue: true)) {
      throw ForceExit.success('Project verification failed');
    }
  }
}
