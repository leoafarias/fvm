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

  bool get exists =>
      FileSystemEntity.typeSync(this) != FileSystemEntityType.notFound;

  String? get read => exists ? file.readAsStringSync() : null;

  void write(String contents) {
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(contents);
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
