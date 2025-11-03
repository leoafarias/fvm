import 'dart:async';

import 'package:pub_semver/pub_semver.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../utils/exceptions.dart';
import 'workflow.dart';

class CheckProjectConstraintsWorkflow extends Workflow {
  const CheckProjectConstraintsWorkflow(super.context);

  /// Checks if the Flutter SDK version used in the project meets the specified constraints.
  FutureOr<bool> call(
    Project project,
    CacheFlutterVersion cachedVersion, {
    required bool force,
  }) {
    final sdkVersion = cachedVersion.dartSdkVersion;
    final constraints = project.sdkConstraint;

    if (sdkVersion == null ||
        constraints == null ||
        constraints.isEmpty ||
        sdkVersion.isEmpty) {
      logger.debug(
        'No SDK constraints to check or missing SDK version information',
      );

      return false;
    }

    Version dartSdkVersion;
    try {
      dartSdkVersion = Version.parse(sdkVersion);
    } on FormatException catch (e) {
      logger.warn('Could not parse Flutter SDK version $sdkVersion: $e');
      if (force) {
        logger.warn('Continuing anyway due to force flag');

        return false;
      }
      logger
        ..warn('Could not parse Flutter SDK version $sdkVersion: $e')
        ..info()
        ..info('Continuing without checking version constraints');

      return false;
    }

    final allowedInConstraint = constraints.allows(dartSdkVersion);
    final message =
        '${cachedVersion.printFriendlyName} has Dart SDK $sdkVersion';

    if (!allowedInConstraint) {
      logger
        ..info(
          '$message does not meet the project constraints of $constraints.',
        )
        ..info('This could cause unexpected behavior or issues.')
        ..info('');

      if (force) {
        logger.warn(
          'Skipping version constraint confirmation because of --force flag detected',
        );

        return false;
      }

      if (!logger.confirm('Would you like to proceed?', defaultValue: false)) {
        throw AppException(
          'The Flutter SDK version $sdkVersion is not compatible with the project constraints. You may need to adjust the version to avoid potential issues.',
        );
      }
    }

    return true;
  }
}
