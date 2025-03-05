import '../models/flutter_version_model.dart';
import '../services/git_service.dart';
import '../utils/exceptions.dart';
import '../utils/extensions.dart';
import '../utils/git_utils.dart';
import 'workflow.dart';

class ValidateFlutterVersionWorkflow extends Workflow {
  ValidateFlutterVersionWorkflow(super.context);

  Future<FlutterVersion> call(String version, {bool force = false}) async {
    final flutterVersion = FlutterVersion.parse(version);

    if (flutterVersion.fromFork) {
      logger.debug('Forked version: $version');

      // Check if fork exists on config
      final fork = context.config.forks
          .firstWhereOrNull((f) => f.alias == flutterVersion.fork);

      if (fork == null) {
        throw AppException(
          'Fork "${flutterVersion.fork}" has not been configured. '
          'Please add it to your configuration first.',
        );
      }
    }

    // If its channel or commit no need for further validation
    if (flutterVersion.isChannel || flutterVersion.isCustom) {
      return flutterVersion;
    }

    if (flutterVersion.isRelease) {
      final isTag =
          await get<GitService>().isGitReference(flutterVersion.version);

      if (isTag) {
        return flutterVersion;
      }
      logger.warn(
        'Flutter version: ${flutterVersion.version} is not a valid tag',
      );
    }

    if (flutterVersion.isUnknownRef) {
      final isReference =
          await get<GitService>().isGitReference(flutterVersion.version);

      if (isReference || isPossibleGitCommit(version)) {
        return flutterVersion;
      }

      logger.warn(
        'Flutter version: ${flutterVersion.version} is not a valid git reference',
      );
    }

    if (force) {
      logger.warn('Continuing with invalid version, force flag was used');

      return flutterVersion;
    }

    final askConfirmation = logger.confirm(
      'Do you want to continue?',
      defaultValue: false,
    );
    if (askConfirmation || force) {
      // Jump a line after confirmation
      logger.info();

      return flutterVersion;
    }

    throw AppException('$version is not a valid Flutter version');
  }
}
