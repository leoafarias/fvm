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
      final fork = context.config.forks.firstWhereOrNull(
        (f) => f.name == flutterVersion.fork,
      );

      if (fork == null) {
        // For unknownRef types (e.g., feature/my-branch), the slash is likely
        // part of a git branch name, not a fork alias. Treat the whole input
        // as a git reference.
        if (flutterVersion.isUnknownRef) {
          logger.debug(
            'No fork alias "${flutterVersion.fork}" configured, '
            'treating "$version" as git reference',
          );

          return FlutterVersion.gitReference(version);
        }

        // For channel/release forms (e.g., myfork/stable, myfork/3.24.0),
        // the user clearly intended a configured fork alias.
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
