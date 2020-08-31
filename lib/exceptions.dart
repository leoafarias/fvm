import 'package:fvm/src/releases_api/releases_client.dart';
import 'package:fvm/src/utils/logger.dart';

/// Logs error for verbose output
dynamic logVerboseError(Exception err) {
  if (logger.isVerbose) {
    logger.stderr(err?.toString());
  }
}

/// Exception cloning channel
class ExceptionCouldNotClone implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionCouldNotClone([this.message = '']);
  @override
  String toString() => 'Could not clone repository: $message';
}

/// Not a valid channel exception
class ExceptionNotValidChannel implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionNotValidChannel([this.message = '']);
  @override
  String toString() => 'ExceptionNotValidChannel: $message';
}

/// Not a valid version exception
class ExceptionNotValidVersion implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionNotValidVersion([this.message = '']);

  @override
  String toString() => 'ExceptionNotValidVersion: $message';
}

/// The folder cannot be set incorrectly.
class ExceptionErrorFlutterPath implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionErrorFlutterPath([this.message = '']);

  @override
  String toString() => 'ExceptionErrorFlutterPath: $message';
}

/// Not a valid version exception
class ExceptionCouldNotReadConfig implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionCouldNotReadConfig([this.message = '']);

  @override
  String toString() => 'ExceptionCouldNotReadConfig: $message';
}

/// Provide a channel or version
class ExceptionMissingChannelVersion implements Exception {
  final message = 'Need to provide a channel or a version.';

  /// Constructor
  ExceptionMissingChannelVersion();

  @override
  String toString() {
    return message;
  }
}

/// Could not fetch Flutter releases
class ExceptionCouldNotFetchReleases implements Exception {
  final message =
      '''Failed to retrieve the Flutter SDK from: ${getReleasesUrl()}\n Fvm will use the value set on env FLUTTER_STORAGE_BASE_URL to check versions.\nif you're located in China, please see this page:
  https://flutter.dev/community/china''';

  /// Constructor
  ExceptionCouldNotFetchReleases();

  @override
  String toString() {
    return message;
  }
}

/// Cannot find a config for the project
class ExceptionProjectConfigNotFound implements Exception {
  final message = 'No config found for this project.';

  /// Constructor
  ExceptionProjectConfigNotFound();

  @override
  String toString() {
    return message;
  }
}
