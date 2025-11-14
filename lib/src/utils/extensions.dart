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
  /// Creates a symlink from [source] to the [target].
  ///
  /// If the link already points to the correct target, does nothing.
  /// Handles broken symlinks that may result from interrupted operations.
  void createLink(String targetPath) {
    final target = Directory(targetPath);

    // Check if link already exists and points to correct target
    if (existsSync()) {
      try {
        if (targetSync() == target.path) {
          return; // Already correct, nothing to do
        }
      } on FileSystemException {
        // Broken symlink, will recreate below
      }
      // Link exists but is wrong/broken, delete it
      deleteSync();
    }

    // Create the new link
    createSync(target.path, recursive: true);
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
