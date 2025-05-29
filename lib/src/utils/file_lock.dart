import 'dart:async';
import 'dart:io';

/// File-based locking mechanism with automatic expiration.
/// Prevents concurrent access to shared resources across processes.
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
  void unlock() => _lockExists ? _file.deleteSync() : null;

  /// Returns true if the file exists and its stored timestamp is within [threshold] from now.
  bool isLockedWithin(Duration threshold) =>
      _lockExists &&
      (lastModified!.isAfter(DateTime.now().subtract(threshold)));

  /// Polls until the file's timestamp is older than [lockExpiration].
  Future<void Function()> getLock({Duration? pollingInterval}) async {
    while (isLocked) {
      await Future.delayed(
        pollingInterval ?? const Duration(milliseconds: 100),
      );
    }

    lock();

    return () => unlock();
  }
}
