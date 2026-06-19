import 'dart:io';

/// Deletes [directory] with retries on Windows to work around file locks.
///
/// Returns `true` when the directory no longer exists. On failure the last
/// [FileSystemException] is either rethrown ([requireSuccess] = true) or
/// forwarded to [onFinalError] before returning `false`.
Future<bool> deleteDirectoryWithRetry(
  Directory directory, {
  bool requireSuccess = true,
  int windowsAttempts = 5,
  Duration retryDelay = const Duration(milliseconds: 200),
  void Function(FileSystemException error)? onFinalError,
}) async {
  if (!directory.existsSync()) return true;

  final attempts = Platform.isWindows ? windowsAttempts : 1;
  for (var attempt = 1; attempt <= attempts; attempt++) {
    try {
      directory.deleteSync(recursive: true);

      return true;
    } on FileSystemException catch (error) {
      final isLastAttempt = attempt == attempts;
      if (isLastAttempt) {
        if (requireSuccess) rethrow;
        onFinalError?.call(error);

        return false;
      }
      await Future<void>.delayed(retryDelay * attempt);
    }
  }

  return false;
}
