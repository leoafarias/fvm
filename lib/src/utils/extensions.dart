import 'dart:io';

extension ListExtension<T> on Iterable<T> {
  /// Returns firstWhereOrNull
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }

    return null;
  }
}

extension IOExtensions on String {
  Directory get dir => Directory(this);
  File get file => File(this);
  Link get link => Link(this);

  bool exists() => type() != FileSystemEntityType.notFound;

  FileSystemEntityType type() => FileSystemEntity.typeSync(this);

  bool isDir() => type() == FileSystemEntityType.directory;
  bool isFile() => type() == FileSystemEntityType.file;
}

extension FileExtensions on File {
  String? read() => existsSync() ? readAsStringSync() : null;
  void write(String contents) {
    if (existsSync()) {
      writeAsStringSync(contents);
    } else {
      createSync(recursive: true);
      writeAsStringSync(contents);
    }
  }
}

extension DirectoryExtensions on Directory {
  void deleteIfExists() {
    if (existsSync()) {
      deleteSync(recursive: true);
    }
  }

  void ensureExists() {
    if (!existsSync()) {
      createSync(recursive: true);
    }
  }
}

extension LinkExtensions on Link {
  /// Creates a symlink from [source] to the [target] with atomic operations.
  /// Handles race conditions where the link might be modified by another process.
  void createLink(String targetPath) {
    final target = Directory(targetPath);

    try {
      // Check if link already points to the correct target
      if (existsSync()) {
        try {
          final currentTarget = targetSync();
          if (currentTarget == target.path) {
            // Already pointing to correct target, nothing to do
            return;
          }
          // Link exists but points to wrong target, delete it
          deleteSync();
        } on FileSystemException {
          // Link was deleted/modified by another process between existsSync() and targetSync()
          // Continue to create the new link
        }
      }

      // Create the new link
      // Use try-catch to handle race where another process creates a link first
      try {
        createSync(target.path, recursive: true);
      } on FileSystemException catch (e) {
        // If link already exists (created by another process), verify it points to correct target
        if (existsSync()) {
          try {
            final currentTarget = targetSync();
            if (currentTarget == target.path) {
              // Another process created the correct link, we're done
              return;
            }
            // Link points to wrong target, try to delete and recreate
            deleteSync();
            createSync(target.path, recursive: true);
          } on FileSystemException {
            // Race condition: link was modified again, rethrow original error
            rethrow;
          }
        } else {
          // Link doesn't exist, rethrow original error
          rethrow;
        }
      }
    } on FileSystemException {
      // Final attempt failed, rethrow to caller
      rethrow;
    }
  }
}

extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    final firstChar = substring(0, 1).toUpperCase();
    final remainingChars = substring(1);

    return '$firstChar$remainingChars';
  }
}
