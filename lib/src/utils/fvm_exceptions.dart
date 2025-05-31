import 'dart:io';
import 'package:io/io.dart';

/// Base exception for all FVM-related errors
/// Provides consistent error handling with proper exit codes
class FvmException implements Exception {
  /// User-readable error message
  final String message;

  /// Optional additional details for debugging
  final String? details;

  /// Exit code to use when this exception causes program termination
  final int exitCode;

  const FvmException(this.message, {this.details, this.exitCode = 1});

  @override
  String toString() => message;
}

/// Exception for command usage errors (wrong arguments, etc.)
class FvmUsageException extends FvmException {
  final String usage;

  const FvmUsageException(
    super.message,
    this.usage, {
    super.exitCode = 64, // Standard exit code for usage errors
  });
}

/// Exception that should cause immediate program exit
class FvmForceExit extends FvmException {
  const FvmForceExit(super.message, {required super.exitCode});

  /// Create a successful exit (useful for --help, --version, etc.)
  const FvmForceExit.success([String? message])
      : super(message ?? '', exitCode: 0);

  /// Create an error exit
  const FvmForceExit.error(String message, {int exitCode = 1})
      : super(message, exitCode: exitCode);
}

/// Utility functions for common exception scenarios
extension FvmExceptionHelpers on FvmException {
  /// Create exception for missing required arguments
  static FvmUsageException missingArgument(String arg, String usage) =>
      FvmUsageException('Missing required argument: $arg', usage);

  /// Create exception for invalid version format
  static FvmException invalidVersion(String version) => FvmException(
        'Invalid version format: $version',
        exitCode: 1,
      );

  /// Create exception for missing Flutter SDK
  static FvmException flutterNotFound(String version) => FvmException(
        'Flutter SDK $version is not installed',
        details: 'Run: fvm install $version',
        exitCode: 1,
      );

  /// Create exception for permission issues
  static FvmException permissionDenied([String? path]) => FvmException(
        'Permission denied${path != null ? ' for path: $path' : ''}',
        details: 'Try running with sudo or administrator privileges',
        exitCode: ExitCode.noPerm.code,
      );
}

/// Check if a FileSystemException requires elevated privileges
bool needsPrivilegedAccess(FileSystemException err) {
  return err.osError?.errorCode == 1314 && Platform.isWindows;
}
