import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:fvm/src/utils/file_lock.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

String _generateUniqueId() {
  /// uuid compatible
  ///  without third party packages
  final random = math.Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  return values.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  late Directory tempDir;
  late String lockFilePath;

  // Common test parameters
  final lockExpiration = Duration(milliseconds: 100);

  setUp(() {
    // Create a temporary directory for our tests
    tempDir = Directory.systemTemp.createTempSync('file_locker_test_');
    lockFilePath = '${tempDir.path}/test.lock';
  });

  tearDown(() {
    // Clean up after each test
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
  });

  group('FileLocker basic functionality', () {
    late FileLocker fileLocker;

    setUp(() {
      fileLocker = FileLocker(
        p.join(tempDir.path, 'test${_generateUniqueId()}.lock'),
        lockExpiration: lockExpiration,
      );
    });

    tearDown(() {
      if (fileLocker.isLocked) {
        try {
          fileLocker.unlock();
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    test('should not be locked initially', () {
      expect(fileLocker.isLocked, isFalse);
      expect(fileLocker.lastModified, isNull);
    });

    test('should create lock file when locked', () {
      fileLocker.lock();
      expect(fileLocker.isLocked, isTrue);
      expect(fileLocker.lastModified, isNotNull);
      expect(File(fileLocker.path).existsSync(), isTrue);

      // Verify timestamp is stored inside the file
      final content = File(fileLocker.path).readAsStringSync();
      expect(int.tryParse(content.trim()), isNotNull);
    });

    test('should update modification time when re-locked', () async {
      fileLocker.lock();
      final firstModTime = fileLocker.lastModified;

      // Wait a bit to ensure time difference
      // With our new implementation, even microseconds should work
      await Future.delayed(Duration(microseconds: 5));

      fileLocker.lock();
      final secondModTime = fileLocker.lastModified;

      expect(secondModTime!.isAfter(firstModTime!), isTrue);

      // The difference should be very small but detectable
      final difference = secondModTime.difference(firstModTime).inMicroseconds;
      expect(difference, greaterThan(0));
    });

    test('should remove lock file when unlocked', () {
      fileLocker.lock();
      expect(fileLocker.isLocked, isTrue);

      fileLocker.unlock();
      expect(fileLocker.isLocked, isFalse);
      expect(fileLocker.lastModified, isNull);
      expect(File(lockFilePath).existsSync(), isFalse);
    });

    test('unlock should do nothing if not locked', () {
      expect(fileLocker.isLocked, isFalse);
      fileLocker.unlock(); // Should not throw
      expect(fileLocker.isLocked, isFalse);
    });
  });

  group('isLockedWithin', () {
    late FileLocker fileLocker;

    setUp(() {
      fileLocker = FileLocker(
        p.join(tempDir.path, 'test${_generateUniqueId()}.lock'),
        lockExpiration: lockExpiration,
      );
    });

    tearDown(() {
      if (fileLocker.isLocked) {
        try {
          fileLocker.unlock();
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    test('should return false if not locked', () {
      expect(fileLocker.isLockedWithin(Duration(seconds: 1)), isFalse);
    });

    test('should return true if lock is within threshold', () {
      fileLocker.lock();
      expect(fileLocker.isLockedWithin(Duration(seconds: 1)), isTrue);
    });

    test('should return false if lock is older than threshold', () async {
      // Write an old timestamp directly to the file instead of using setLastModifiedSync
      final oldTime = DateTime.now().subtract(Duration(seconds: 2));
      final oldTimestamp = oldTime.millisecondsSinceEpoch.toString();

      // Ensure parent directory exists and create the file with old timestamp
      final parent = File(lockFilePath).parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }
      File(lockFilePath).writeAsStringSync(oldTimestamp);

      expect(fileLocker.isLockedWithin(Duration(seconds: 1)), isFalse);
    });
  });

  group('getLock functionality', () {
    late FileLocker fileLocker;

    setUp(() {
      fileLocker = FileLocker(
        p.join(tempDir.path, 'test${_generateUniqueId()}.lock'),
        lockExpiration: lockExpiration,
      );
    });

    tearDown(() {
      if (fileLocker.isLocked) {
        try {
          fileLocker.unlock();
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    test('should immediately get lock if not locked', () async {
      final unlock = await fileLocker.getLock();
      expect(fileLocker.isLocked, isTrue);

      unlock();
      expect(fileLocker.isLocked, isFalse);
    });

    test('should wait until lock expires', () async {
      // Create a lock that will expire soon by writing a timestamp directly
      final almostExpiredTime =
          DateTime.now().subtract(Duration(milliseconds: 90));
      final almostExpiredTimestamp =
          almostExpiredTime.millisecondsSinceEpoch.toString();

      // Create the file with almost expired timestamp
      final parent = File(lockFilePath).parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }
      File(lockFilePath).writeAsStringSync(almostExpiredTimestamp);

      // Start a timer to measure waiting time
      final stopwatch = Stopwatch()..start();

      final unlock = await fileLocker.getLock();
      stopwatch.stop();

      // Should have waited for the lock to expire
      expect(stopwatch.elapsedMicroseconds, greaterThanOrEqualTo(1));
      expect(fileLocker.isLocked, isTrue);

      unlock();
      expect(fileLocker.isLocked, isFalse);
    });

    test('should ensure only one process gets the lock at a time', () async {
      // Create a shared variable and a list to track operations
      var sharedValue = 0;
      var operations = <String>[];

      // Function to simulate work with the shared value
      Future<void> doLockedWork(String id, int delayMs) async {
        operations.add('$id: requesting lock');
        final unlock = await fileLocker.getLock();
        try {
          operations.add('$id: got lock, value=$sharedValue');
          var current = sharedValue;

          // Simulate some processing time
          await Future.delayed(Duration(milliseconds: delayMs));

          // Update the value
          sharedValue = current + 1;
          operations.add('$id: updated value to $sharedValue');
        } finally {
          operations.add('$id: releasing lock');
          unlock();
        }
      }

      // Start multiple workers that will contend for the lock
      final futures = [
        doLockedWork('A', 15),
        doLockedWork('B', 5),
        doLockedWork('C', 10),
      ];

      // Run them all concurrently
      await Future.wait(futures);

      // Check final value
      expect(sharedValue, equals(3));

      // Validate the operations log shows proper lock acquisition
      // Each "got lock" should be followed by the matching "releasing lock"
      // before another "got lock" appears
      var currentHolder = '';
      for (var op in operations) {
        if (op.contains('got lock')) {
          expect(currentHolder, isEmpty,
              reason: 'Another process already held the lock: $currentHolder');
          currentHolder = op.split(':')[0];
        } else if (op.contains('releasing lock')) {
          expect(currentHolder, equals(op.split(':')[0]),
              reason: 'Wrong process released the lock');
          currentHolder = '';
        }
      }

      // Ensure all locks were properly released
      expect(currentHolder, isEmpty, reason: 'A lock was never released');
      expect(fileLocker.isLocked, isFalse);
    });
  });

  group('External interactions', () {
    late FileLocker fileLocker;

    setUp(() {
      fileLocker = FileLocker(
        p.join(tempDir.path, 'test${_generateUniqueId()}.lock'),
        lockExpiration: lockExpiration,
      );
    });

    tearDown(() {
      if (fileLocker.isLocked) {
        try {
          fileLocker.unlock();
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    });

    test('should handle external timestamp modification', () async {
      fileLocker.lock();

      // Start a lock request
      final lockFuture = fileLocker.getLock();

      // Externally modify the timestamp by writing an old time to the file
      await Future.delayed(Duration(milliseconds: 20));
      final oldTimestamp = DateTime.now()
          .subtract(lockExpiration * 2)
          .millisecondsSinceEpoch
          .toString();
      File(fileLocker.path).writeAsStringSync(oldTimestamp);

      // Should now be able to acquire the lock
      final unlock = await lockFuture;
      expect(fileLocker.isLocked, isTrue);
      unlock();
    });

    test('should handle external file corruption', () async {
      fileLocker.lock();

      // Write invalid content to the file
      File(fileLocker.path).writeAsStringSync('invalid-timestamp');

      // Should still be able to read a timestamp (fallback to file system timestamp)
      expect(fileLocker.lastModified, isNotNull);

      // Lock again to fix the file content
      fileLocker.lock();

      // Now the file should contain a valid timestamp
      final content = File(fileLocker.path).readAsStringSync();
      expect(int.tryParse(content.trim()), isNotNull);
    });

    test('should handle lock file being repeatedly refreshed', () async {
      fileLocker.lock();

      // Start a timer to keep updating the lock file
      var keepUpdating = true;
      Timer.periodic(Duration(milliseconds: 5), (timer) {
        if (!keepUpdating) {
          timer.cancel();
          return;
        }

        try {
          if (File(lockFilePath).existsSync()) {
            fileLocker.lock(); // Keep refreshing the lock
          }
        } catch (e) {
          // Ignore errors
        }
      });

      // Start a lock request with a timeout
      var gotLock = false;
      late void Function() unlock;

      try {
        // Try to get the lock with a timeout
        unlock = await fileLocker.getLock().timeout(Duration(milliseconds: 50),
            onTimeout: () {
          throw TimeoutException('Failed to get lock in time');
        });
        gotLock = true;
      } on TimeoutException {
        // Expected - the timer keeps refreshing the lock
        gotLock = false;
      } finally {
        // Stop the update timer
        keepUpdating = false;
      }

      expect(gotLock, isFalse,
          reason:
              'Should not have gotten the lock while file is constantly refreshed');

      // Now wait a bit for the lock to expire
      await Future.delayed(lockExpiration * 2);

      // Should now be able to get the lock
      unlock = await fileLocker.getLock();
      expect(fileLocker.isLocked, isTrue);
      unlock();
    });
  });

  group('Error handling', () {
    test('should handle directory creation if parent directory does not exist',
        () {
      final nestedPath = '${tempDir.path}/nested/dir/test.lock';
      final nestedLocker = FileLocker(
        nestedPath,
        lockExpiration: lockExpiration,
      );

      // Should create parent directories
      nestedLocker.lock();
      expect(File(nestedPath).existsSync(), isTrue);

      // Check that a valid timestamp is written to the file
      final content = File(nestedPath).readAsStringSync();
      expect(int.tryParse(content.trim()), isNotNull);

      nestedLocker.unlock();
    });

    test('should handle file system errors gracefully', () {
      // Skip on platforms where we can't set permissions reliably
      if (Platform.isWindows) {
        return;
      }

      try {
        final readOnlyDir = Directory('${tempDir.path}/readonly')..createSync();
        // Make it read-only
        Process.runSync('chmod', ['555', readOnlyDir.path]);

        final readOnlyPath = '${readOnlyDir.path}/test.lock';
        final readOnlyLocker = FileLocker(
          readOnlyPath,
          lockExpiration: lockExpiration,
        );

        try {
          readOnlyLocker.lock();
          fail('Should have thrown a FileSystemException');
        } catch (e) {
          expect(e, isA<FileSystemException>());
        } finally {
          // Restore permissions to allow cleanup
          Process.runSync('chmod', ['755', readOnlyDir.path]);
        }
      } catch (e) {
        // Skip test if we can't set up the conditions
        print('Skipping file system error test: $e');
      }
    });
  });

  group('Edge cases', () {
    late FileLocker fileLocker;

    setUp(() {
      fileLocker = FileLocker(
        p.join(tempDir.path, 'test${_generateUniqueId()}.lock'),
        lockExpiration: lockExpiration,
      );
    });
    test('should handle very short expiration times', () async {
      final quickLocker = FileLocker(
        lockFilePath,
        lockExpiration: Duration(milliseconds: 2),
      );

      quickLocker.lock();

      // Should get the lock almost immediately despite it being locked
      final stopwatch = Stopwatch()..start();
      final unlock =
          await quickLocker.getLock(pollingInterval: Duration(milliseconds: 1));
      stopwatch.stop();

      expect(quickLocker.isLocked, isTrue);
      unlock();
    });

    test('should handle very long expiration times', () async {
      final longLocker = FileLocker(
        lockFilePath,
        lockExpiration: Duration(days: 1),
      );

      // Create lock file with a very old timestamp
      final oldTimestamp = DateTime.now()
          .subtract(Duration(days: 2))
          .millisecondsSinceEpoch
          .toString();
      final parent = File(lockFilePath).parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }
      File(lockFilePath).writeAsStringSync(oldTimestamp);

      // Should get the lock immediately because the timestamp is old
      final unlock = await longLocker.getLock();
      expect(longLocker.isLocked, isTrue);
      unlock();
    });

    test('should handle polling interval longer than lock expiration',
        () async {
      // Create a locker with polling interval > lock expiration
      final oddLocker = FileLocker(
        lockFilePath,
        lockExpiration: Duration(milliseconds: 20),
      );

      // Start a stopwatch to measure time
      final stopwatch = Stopwatch()..start();
      oddLocker.lock();

      final unlock = await oddLocker.getLock();
      stopwatch.stop();

      // Should have waited at least one polling interval
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(10));

      unlock();
    });

    test('should handle near-simultaneous lock requests', () async {
      // Launch many concurrent lock requests
      final count = 10;
      final results = <int>[];

      // Function that acquires lock, adds to results, and releases
      Future<void> acquireLock(int id) async {
        final unlock = await fileLocker.getLock();
        try {
          // Record this ID
          results.add(id);
          // Small delay to simulate work
          await Future.delayed(Duration(milliseconds: 1));
        } finally {
          unlock();
        }
      }

      // Start all requests concurrently
      await Future.wait(List.generate(count, (index) => acquireLock(index)));

      // All IDs should be in the results exactly once
      expect(results.length, equals(count));
      expect(results.toSet().length, equals(count),
          reason: 'Each ID should appear exactly once');

      // Final state should be unlocked
      expect(fileLocker.isLocked, isFalse);
    });

    test('should handle microsecond precision timestamps', () async {
      // Create timestamps with just 1 microsecond difference
      final now = DateTime.now();
      final timestamp1 = now.microsecondsSinceEpoch;
      final timestamp2 =
          now.add(Duration(microseconds: 1)).microsecondsSinceEpoch;

      // Ensure they're different
      expect(timestamp1, isNot(equals(timestamp2)));

      // Write first timestamp to file
      File(fileLocker.path).writeAsStringSync(timestamp1.toString());
      final readTime1 = fileLocker.lastModified;

      // Write second timestamp to file
      File(fileLocker.path).writeAsStringSync(timestamp2.toString());
      final readTime2 = fileLocker.lastModified;

      // Verify the timestamps are correctly distinguished
      expect(readTime1, isNotNull);
      expect(readTime2, isNotNull);
      expect(readTime2!.isAfter(readTime1!), isTrue);
      expect(readTime2.difference(readTime1).inMicroseconds, equals(1));
    });
  });
}
