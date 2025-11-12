import 'dart:async';
import 'dart:io';

/// File-based locking mechanism with automatic expiration.
///
/// Provides cross-process synchronization using file-system locks with
/// timestamp-based expiration to prevent deadlocks from crashed processes.
///
/// The lock uses a file to coordinate access between processes. A timestamp
/// is stored in the file to determine when the lock was acquired. If a process
/// crashes while holding the lock, the lock will automatically expire after
/// the configured [lockExpiration] duration.
///
/// ## Usage
///
/// ```dart
/// // Create a file locker with 10-minute expiration
/// final locker = FileLocker(
///   '/path/to/lock.file',
///   lockExpiration: Duration(minutes: 10),
/// );
///
/// // Acquire the lock
/// final unlock = await locker.getLock();
///
/// try {
///   // Critical section - only one process can execute this at a time
///   print('Doing protected work...');
/// } finally {
///   // Always release the lock
///   unlock();
/// }
/// ```
///
/// ## Timeout Support
///
/// You can specify a timeout to prevent waiting indefinitely for a lock:
///
/// ```dart
/// try {
///   final unlock = await locker.getLock(
///     timeout: Duration(minutes: 5),
///   );
///   try {
///     // Critical section
///   } finally {
///     unlock();
///   }
/// } on TimeoutException {
///   print('Could not acquire lock within timeout');
/// }
/// ```
///
/// ## Thread Safety
///
/// This implementation is safe for cross-process synchronization but not
/// for cross-thread synchronization within the same process. If you need
/// thread-level locking, use Dart's built-in synchronization primitives.
///
/// ## Lock Expiration
///
/// Locks automatically expire after [lockExpiration] to prevent deadlocks
/// from crashed processes. Choose an expiration time longer than your
/// expected critical section duration to avoid premature lock release.
class FileLocker {
  /// The file path used for the lock file.
  final String path;

  /// Duration after which the lock automatically expires.
  final Duration lockExpiration;

  /// Creates a new FileLocker instance.
  const FileLocker(this.path, {required this.lockExpiration});

  File get _file => File(path);

  bool get _lockExists => _file.existsSync();

  /// Returns true if the lock is currently active and not expired.
  bool get isLocked => _lockExists && isLockedWithin(lockExpiration);

  /// Gets the lock creation timestamp from file content or modification time.
  DateTime? get lastModified {
    if (!_lockExists) return null;

    try {
      final content = _file.readAsStringSync();
      final timestamp = int.parse(content.trim());

      return DateTime.fromMicrosecondsSinceEpoch(timestamp);
    } catch (e) {
      // If there's an error reading/parsing the timestamp,
      // return the file system timestamp as a fallback
      return _file.lastModifiedSync();
    }
  }

  /// Create or update the lock by writing the current timestamp to the file.
  void lock() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toString();

    if (_lockExists) {
      _file.writeAsStringSync(timestamp);
    } else {
      // Ensure parent directory exists
      final parent = _file.parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }
      _file.writeAsStringSync(timestamp);
    }
  }

  /// Remove the lock.
  void unlock() {
    if (_lockExists) {
      _file.deleteSync();
    }
  }

  /// Returns true if the file exists and its stored timestamp is within [threshold] from now.
  bool isLockedWithin(Duration threshold) {
    if (!_lockExists) return false;
    final modified = lastModified;
    if (modified == null) return false;
    return modified.isAfter(DateTime.now().subtract(threshold));
  }

  /// Polls until the file's timestamp is older than [lockExpiration].
  ///
  /// Optionally specify a [timeout] duration. If the lock cannot be acquired
  /// within the timeout period, a [TimeoutException] is thrown.
  ///
  /// The [pollingInterval] controls how often to check for the lock.
  Future<void Function()> getLock({
    Duration? pollingInterval,
    Duration? timeout,
  }) async {
    final stopwatch = timeout != null ? (Stopwatch()..start()) : null;
    final interval = pollingInterval ?? const Duration(milliseconds: 100);

    while (isLocked) {
      // Check if timeout has been exceeded
      if (stopwatch != null && stopwatch.elapsed >= timeout!) {
        throw TimeoutException(
          'Failed to acquire lock after ${timeout.inSeconds} seconds',
          timeout,
        );
      }

      await Future.delayed(interval);
    }

    lock();

    return () => unlock();
  }
}
