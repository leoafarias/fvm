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

  String _encodeTimestamp(DateTime now) => now.microsecondsSinceEpoch.toString();

  DateTime? _parseTimestamp(String content) {
    final timestamp = int.tryParse(content.trim());
    return timestamp == null
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(timestamp);
  }

  bool _isActive(DateTime? lockTime, Duration expiration, DateTime now) =>
      lockTime != null && lockTime.isAfter(now.subtract(expiration));

  void _ensureParentExists() {
    final parent = _file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
  }

  /// Returns true if the lock is currently active and not expired.
  bool get isLocked => _lockExists && isLockedWithin(lockExpiration);

  /// Gets the lock creation timestamp from file content or modification time.
  DateTime? get lastModified {
    if (!_lockExists) return null;

    try {
      final content = _file.readAsStringSync();
      final parsed = _parseTimestamp(content);
      if (parsed != null) {
        return parsed;
      }
    } catch (e) {
      // If there's an error reading/parsing the timestamp,
      // return the file system timestamp as a fallback
      return _file.lastModifiedSync();
    }

    return _file.lastModifiedSync();
  }

  /// Create or update the lock by writing the current timestamp to the file.
  void lock() {
    _ensureParentExists();
    _file.writeAsStringSync(_encodeTimestamp(DateTime.now()));
  }

  /// Remove the lock.
  void unlock() => _lockExists ? _file.deleteSync() : null;

  /// Returns true if the file exists and its stored timestamp is within [threshold] from now.
  bool isLockedWithin(Duration threshold) =>
      _lockExists && _isActive(lastModified, threshold, DateTime.now());

  /// Polls until the file's timestamp is older than [lockExpiration].
  /// Uses OS-level file locking to prevent race conditions between processes.
  Future<void Function()> getLock({Duration? pollingInterval}) async {
    final interval = pollingInterval ?? const Duration(milliseconds: 100);

    // Create parent directory once before the loop
    _ensureParentExists();

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
            final lockTime = _parseTimestamp(content);
            if (_isActive(lockTime, lockExpiration, DateTime.now())) {
              // Lock is still valid - release and wait
              file.unlockSync();
              await Future.delayed(interval);
              continue;
            }
          }

          // Write new timestamp - write first, then truncate to exact length
          // This order is more reliable on Windows where truncate-then-write
          // in append mode can have unexpected behavior
          final timestampBytes =
              utf8.encode(_encodeTimestamp(DateTime.now()));
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
