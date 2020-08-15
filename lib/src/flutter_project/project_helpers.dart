import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:path/path.dart' as path;

bool isFlutterProject() {
  return kLocalProjectPubspec.existsSync();
}

Future<void> getLocalFlutterProjects(String dirPath) async {
  var dir = Directory(dirPath);
  List contents = dir.listSync(recursive: true);
  for (final ioEntity in contents) {
    if (ioEntity is Directory) {
      final pubspec = File(path.join(ioEntity.path, 'pubspec.yaml'));
      // TODO move fvm_config.json to constant
      final fvmConfig =
          File(path.join(ioEntity.path, kFvmDirName, 'fvm_config.json'));

      if (pubspec.existsSync() && fvmConfig.existsSync()) {}
    }
  }
}
