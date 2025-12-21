import 'dart:async';
import 'dart:convert';
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
  /// Uses OS-level file locking to prevent race conditions between processes.
  Future<void Function()> getLock({Duration? pollingInterval}) async {
    final interval = pollingInterval ?? const Duration(milliseconds: 100);

    // Create parent directory once before the loop
    final parent = _file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    while (true) {
      RandomAccessFile? file;
      try {
        file = _file.openSync(mode: FileMode.append);
        try {
          file.lockSync(FileLock.exclusive);

          // Check if existing timestamp is expired
          if (file.lengthSync() > 0) {
            file.setPositionSync(0);
            final content = utf8.decode(file.readSync(file.lengthSync()));
            final timestamp = int.tryParse(content.trim());
            if (timestamp != null) {
              final lockTime = DateTime.fromMicrosecondsSinceEpoch(timestamp);
              if (lockTime.isAfter(DateTime.now().subtract(lockExpiration))) {
                // Lock is still valid - release and wait
                file.unlockSync();
                await Future.delayed(interval);
                continue;
              }
            }
          }

          // Write new timestamp - write first, then truncate to exact length
          // This order is more reliable on Windows where truncate-then-write
          // in append mode can have unexpected behavior
          final timestampBytes =
              utf8.encode(DateTime.now().microsecondsSinceEpoch.toString());
          file.setPositionSync(0);
          file.writeFromSync(timestampBytes);
          file.truncateSync(timestampBytes.length);
          file.flushSync();
          file.unlockSync();

          return () => unlock();
        } finally {
          file.closeSync();
        }
      } on FileSystemException {
        // Lock is held by another process
        await Future.delayed(interval);
      }
    }
  }
}
