#!/usr/bin/env dart

import 'dart:io';

import 'package:path/path.dart';
import 'package:pubspec2/pubspec2.dart';

void main() {
  // Get the pubspec file
  final pubspecFile = File(join(Directory.current.path, 'pubspec.yaml'));
  // Read the pubspec file
  final pubspecContent = pubspecFile.readAsStringSync();
  final pubspec = PubSpec.fromYamlString(pubspecContent);

  // Get the version
  final version = pubspec.version.toString();

  final versionFile = File(
    join(Directory.current.path, 'lib', 'src', 'version.g.dart'),
  );

  if (versionFile.existsSync()) {
    versionFile.createSync(recursive: true);
  }

// Write the following:
// const packageVersion = '2.4.1';
  versionFile.writeAsStringSync(
    "const packageVersion = '$version';",
  );

  print('Version $version written to version.g.dart');
}
