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

  DateTime? get lastModified => isLocked ? _file.lastModifiedSync() : null;

  /// Create or update the lock by setting its last modified time.
  void lock() => isLocked
      ? _file.setLastModifiedSync(DateTime.now())
      : _file.createSync(recursive: true);

  /// Remove the lock.
  void unlock() => isLocked ? _file.deleteSync() : null;

  /// Returns true if the file exists and its modification time is within [threshold] from now.
  bool isLockedWithin(Duration threshold) =>
      isLocked && (lastModified!.isAfter(DateTime.now().subtract(threshold)));

  /// Polls until the file’s last modification is older than [lockExpiration].
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
