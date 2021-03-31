/// Exception for internal FVM Errors
class FvmInternalError implements Exception {
  /// Message of erro
  final String message;

  /// Constructor
  const FvmInternalError([this.message = '']);

  @override
  String toString() => 'Internal Error: $message';
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
