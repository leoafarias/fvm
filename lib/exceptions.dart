abstract class FvmException implements Exception {
  /// Message of error
  final String message;

  /// Constructor
  const FvmException(this.message);

  @override
  String toString() => 'FVM Exception: \n $message';
}

class FvmError extends FvmException {
  /// Constructor
  const FvmError(
    super.message, [
    this.exception,
    this.stackTrace,
  ]);

  /// Actual message from exception
  final Exception? exception;

  /// Stack trace of error
  final StackTrace? stackTrace;

  @override
  String toString() => 'FVM Error: \n $message';
}

/// Exception for internal FVM usage

class FvmUsageException implements Exception {
  /// Message of the exception
  final String message;

  /// Constructor of usage exception
  const FvmUsageException([this.message = '']);

  @override
  String toString() => 'Usage Exception: $message';
}
