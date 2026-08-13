import 'dart:io';

import '../services/logger_service.dart';
import 'exceptions.dart';

bool _isLockContentionError(FileSystemException error) {
  final message = error.message.toLowerCase();

  return message.contains('lock failed') ||
      message.contains('resource temporarily unavailable') ||
      message.contains('operation would block') ||
      message.contains('already locked') ||
      message.contains('being used by another process');
}

/// Runs [action] while holding an operating-system lock on [lockFile].
///
/// Lock files are intentionally retained after release so concurrent processes
/// always coordinate through the same filesystem object.
Future<T> withProcessFileLock<T>({
  required File lockFile,
  required FileLock lockMode,
  required String description,
  required Logger logger,
  required Future<T> Function() action,
}) async {
  if (!lockFile.parent.existsSync()) {
    lockFile.parent.createSync(recursive: true);
  }

  RandomAccessFile? lockHandle;
  var lockAcquired = false;
  const retryDelay = Duration(milliseconds: 150);
  const waitLogThreshold = Duration(seconds: 2);
  const maxWait = Duration(minutes: 5);

  try {
    try {
      lockHandle = await lockFile.open(mode: FileMode.write);

      final lockWaitStart = DateTime.now();
      var waitingLogged = false;

      while (!lockAcquired) {
        try {
          await lockHandle.lock(lockMode);
          lockAcquired = true;
        } on FileSystemException catch (error, stackTrace) {
          if (!_isLockContentionError(error)) {
            Error.throwWithStackTrace(
              AppException(
                'Failed to acquire $description lock at ${lockFile.path}: ${error.message}',
              ),
              stackTrace,
            );
          }

          final elapsed = DateTime.now().difference(lockWaitStart);
          if (elapsed > maxWait) {
            Error.throwWithStackTrace(
              AppException(
                'Timed out waiting for $description lock at ${lockFile.path} after ${elapsed.inSeconds}s.',
              ),
              stackTrace,
            );
          }

          if (!waitingLogged && elapsed >= waitLogThreshold) {
            waitingLogged = true;
            logger.debug(
              'Waiting for $description lock at ${lockFile.path}...',
            );
          }

          await Future<void>.delayed(retryDelay);
        }
      }
    } on FileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(
          'Failed to acquire $description lock at ${lockFile.path}: ${error.message}',
        ),
        stackTrace,
      );
    }

    return await action();
  } finally {
    if (lockHandle != null) {
      if (lockAcquired) {
        try {
          await lockHandle.unlock();
        } on FileSystemException catch (error) {
          logger.warn(
            'Failed to unlock $description lock at ${lockFile.path}: ${error.message}',
          );
        }
      }
      try {
        await lockHandle.close();
      } on FileSystemException catch (error) {
        logger.warn(
          'Failed to close $description lock at ${lockFile.path}: ${error.message}',
        );
      }
    }
  }
}
