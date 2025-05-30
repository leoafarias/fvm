import '../models/flutter_version_model.dart';
import '../utils/extensions.dart';
import '../utils/fvm_exceptions.dart';
import 'workflow.dart';

class ValidateFlutterVersionWorkflow extends Workflow {
  const ValidateFlutterVersionWorkflow(super.context);

  FlutterVersion call(String version) {
    final flutterVersion = FlutterVersion.parse(version);

    if (flutterVersion.fromFork) {
      logger.debug('Forked version: $version');

      // Check if fork exists on config
      final fork = context.config.forks
          .firstWhereOrNull((f) => f.name == flutterVersion.fork);

      if (fork == null) {
        throw FvmException(
          'Fork "${flutterVersion.fork}" has not been configured',
          details: 'Add the fork to your configuration first: fvm config',
          exitCode: 1,
        );
      }

      return flutterVersion;
    }

    // If its channel or local version no need for further validation
    if (flutterVersion.isChannel || flutterVersion.isCustom) {
      return flutterVersion;
    }

    // Skip git reference validation - let the installation process handle it
    logger.debug('Skipping git reference validation for version: $version');

    return flutterVersion;
  }
}
