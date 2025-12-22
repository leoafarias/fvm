import 'dart:io';

/// Deletes [directory] with retries on Windows to work around file locks.
///
/// Returns true if the directory is deleted or does not exist. If
/// [requireSuccess] is true, the final failure is rethrown. When
/// [requireSuccess] is false, [onFinalError] is invoked with the last
/// [FileSystemException] before returning false.
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
      final isLastAttempt = !Platform.isWindows || attempt == attempts;
      if (isLastAttempt) {
        if (requireSuccess) {
          rethrow;
        }
        onFinalError?.call(error);
        return false;
      }
      await Future<void>.delayed(
        Duration(milliseconds: retryDelay.inMilliseconds * attempt),
      );
    }
  }

  return false;
}
