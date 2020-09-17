import 'package:fvm/src/releases_api/releases_client.dart';

class UsageError implements Exception {
  final String message;
  const UsageError([this.message = '']);
  @override
  String toString() => 'Usage Error: $message';
}

class InternalError implements Exception {
  final String message;
  const InternalError([this.message = '']);
  @override
  String toString() => 'Internal Error: $message';
}

class SetupError implements Exception {
  final String message;
  const SetupError([this.message = '']);
  @override
  String toString() => 'Setup Error: $message';
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
