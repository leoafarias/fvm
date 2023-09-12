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

String uppercase(String name) {
  return name.split(' ').map((word) {
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}
