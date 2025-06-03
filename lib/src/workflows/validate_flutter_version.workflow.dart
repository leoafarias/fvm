import '../models/flutter_version_model.dart';
import '../utils/exceptions.dart';
import '../utils/extensions.dart';
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
        throw AppDetailedException(
          'Fork "${flutterVersion.fork}" has not been configured',
          'Add the fork to your configuration first: fvm config',
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
