/// Exception cloning channel
class ExceptionCouldNotClone implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionCouldNotClone([this.message = '']);

  String toString() => 'ExceptionCouldNotClone: $message';
}

/// Not a valid channel exception
class ExceptionNotValidChannel implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionNotValidChannel([this.message = '']);

  String toString() => 'ExceptionNotValidChannel: $message';
}

/// Not a valid version exception
class ExceptionNotValidVersion implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionNotValidVersion([this.message = '']);

  String toString() => 'ExceptionNotValidVersion: $message';
}

/// The folder cannot be set incorrectly.
class ExceptionErrorFlutterPath implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionErrorFlutterPath([this.message = '']);

  String toString() => 'ExceptionErrorFlutterPath: $message';
}

/// Not a valid version exception
class ExceptionCouldNotReadConfig implements Exception {
  /// Version
  final String message;

  /// Constructor
  const ExceptionCouldNotReadConfig([this.message = '']);

  String toString() => 'ExceptionCouldNotReadConfig: $message';
}
