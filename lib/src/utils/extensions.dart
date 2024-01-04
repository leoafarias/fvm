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
  /// Creates a symlink from [source] to the [target]
  void createLink(String targetPath) {
    // Check if needs to do anything

    final target = Directory(targetPath);

    final sourceExists = existsSync();
    if (sourceExists && targetSync() == target.path) {
      return;
    }

    if (sourceExists) {
      deleteSync();
    }

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
