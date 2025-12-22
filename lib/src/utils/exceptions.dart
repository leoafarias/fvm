import 'dart:io';

import 'package:io/io.dart';

/// Represents an FVM-specific exception that carries a user-facing message.
///
/// Exceptions of this type are intended to be self-explanatory, no debugging info
class AppException implements Exception {
  /// User-readable error message.
  final String message;

  /// Initializes an instance with a user-readable message.
  const AppException(this.message);

  @override
  String toString() => message;
}

class AppDetailedException extends AppException {
  final String info;

  const AppDetailedException(super.message, this.info);

  @override
  String toString() => message;
}

bool checkIfNeedsPrivilegePermission(FileSystemException err) {
  return err.osError?.errorCode == 1314 && Platform.isWindows;
}

class ForceExit extends AppException {
  final int exitCode;

  const ForceExit(super.message, this.exitCode);

  static ForceExit success([String? message]) =>
      ForceExit(message ?? '', ExitCode.success.code);

  static ForceExit unavailable([String? message]) =>
      ForceExit(message ?? '', ExitCode.unavailable.code);

  @override
  String toString() => message;
}
