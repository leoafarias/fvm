import 'dart:io';

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
  const FvmError(super.message);

  @override
  String toString() => 'FVM Error: \n $message';
}

/// Exception for internal FVM Errors
@Deprecated('Use FvmException instead')
class FvmExceptionStackTrace extends FvmException {
  /// Actual message from exception
  final Exception exception;

  /// Stack trace of error
  final StackTrace stackTrace;

  /// Constructor
  const FvmExceptionStackTrace(
    super.message,
    this.exception,
    this.stackTrace,
  );

  @override
  String toString() =>
      'FVM Error: \n $message \n ${exception.toString()} \n $stackTrace';
}

class FvmProcessRunnerException extends FvmException {
  /// Command that was run
  final ProcessResult result;

  /// Constructor
  const FvmProcessRunnerException(
    super.message, {
    required this.result,
  });

  @override
  String toString() =>
      'FVM Internal Process Exception: \n $message \n Stderr: ${result.stderr} \n Stdout: ${result.stdout}';
}

/// Exception for internal FVM usage
@Deprecated('Use UsageException instead')
class FvmUsageException implements Exception {
  /// Message of the exception
  final String message;

  /// Constructor of usage exception
  const FvmUsageException([this.message = '']);

  @override
  String toString() => 'Usage Exception: $message';
}
