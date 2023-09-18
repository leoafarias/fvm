import 'dart:io';

import 'package:pubspec2/pubspec2.dart';

/// Service to manage FVM Config
class PubspecRepository {
  /// Path where config is stored
  final String _pubspecPath;

  PubspecRepository(this._pubspecPath);

  File get _pubspecFile => File(_pubspecPath);

  PubSpec? load() {
    if (_pubspecFile.existsSync()) {
      final jsonString = _pubspecFile.readAsStringSync();
      return PubSpec.fromYamlString(jsonString);
    }

    return null;
  }
}
