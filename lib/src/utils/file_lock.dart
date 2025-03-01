import 'dart:async';
import 'dart:io';

class FileLocker {
  final String path;
  final Duration lockExpiration;
  final Duration pollingInterval;

  const FileLocker(
    this.path, {
    required this.lockExpiration,
    required this.pollingInterval,
  });

  File get _file => File(path);

  bool get isLocked => _file.existsSync();

  /// Get the timestamp from inside the file contents
  DateTime? get lastModified {
    if (!isLocked) return null;

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

    if (isLocked) {
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
  void unlock() => isLocked ? _file.deleteSync() : null;

  /// Returns true if the file exists and its stored timestamp is within [threshold] from now.
  bool isLockedWithin(Duration threshold) =>
      isLocked && (lastModified!.isAfter(DateTime.now().subtract(threshold)));

  /// Polls until the file's timestamp is older than [lockExpiration].
  Future<Unlock> getLock() async {
    while (isLockedWithin(lockExpiration)) {
      print('Waiting for $path to be unlocked');
      await Future.delayed(pollingInterval);
    }

    lock();

    return unlock;
  }
}

typedef Unlock = void Function();
