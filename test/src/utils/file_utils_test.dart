import 'dart:io';

import 'package:fvm/src/utils/file_utils.dart';
import 'package:test/test.dart';

void main() {
  test('recognizes file-lock contention messages', () {
    for (final message in [
      'Lock failed',
      'Resource temporarily unavailable',
      'Operation would block',
      'Already locked',
      'The process cannot access the file because it is being used by another process',
    ]) {
      expect(
        isFileLockContentionError(FileSystemException(message)),
        isTrue,
        reason: message,
      );
    }
  });

  test('does not classify unrelated filesystem failures as contention', () {
    expect(
      isFileLockContentionError(
        const FileSystemException('Permission denied'),
      ),
      isFalse,
    );
  });
}
