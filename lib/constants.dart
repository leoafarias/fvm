import 'dart:io';

/// Flutter Repo Address
const kFlutterRepo = "https://github.com/flutter/flutter.git";

/// Working Directory for FVM
final kWorkingDirectory = Directory.current;
// TODO: Find better way to join paths
/// Where Flutter SDK Versions are stored
final kVersionsDir = Directory('${kWorkingDirectory.path}/versions');
