import 'dart:io';

import 'package:path/path.dart' as p;

String? _cachedPackageRoot;

/// Resolves fixture paths relative to the fvm package root.
String packageFixturePath(String relativePath) {
  return p.join(_packageRoot(), relativePath);
}

String _packageRoot() {
  final cached = _cachedPackageRoot;
  if (cached != null) return cached;

  final candidates = <String>{
    Directory.current.path,
    if (Platform.environment['PWD'] case final pwd?) pwd,
    if (Platform.environment['INIT_CWD'] case final initCwd?) initCwd,
    p.dirname(Platform.script.toFilePath()),
  };

  for (final start in candidates) {
    var dir = p.normalize(start);
    while (true) {
      final pubspec = File(p.join(dir, 'pubspec.yaml'));
      if (pubspec.existsSync() &&
          pubspec.readAsStringSync().contains('name: fvm')) {
        _cachedPackageRoot = dir;
        return dir;
      }

      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }
  }

  throw StateError('Could not locate fvm package root for test fixtures');
}
