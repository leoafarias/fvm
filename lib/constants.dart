import 'dart:io';
import "package:path/path.dart";

/// Flutter Repo Address
const kFlutterRepo = "https://github.com/flutter/flutter.git";

/// Working Directory for FVM
final kWorkingDirectory = Directory.current;

// Removes the script from path using 'dirname'.
final _fvmBinPath = dirname(Platform.script.path);
// Remove /bin from path
final _fvmRootPath = _fvmBinPath.substring(0, _fvmBinPath.length - 4);

/// Root directory for FVM
final kFvmDir = Directory(_fvmRootPath);
// TODO: Find better way to join paths
/// Where Flutter SDK Versions are stored
final kVersionsDir = Directory('${kFvmDir.path}/versions');

/// Flutter Channels
final kFlutterChannels = ['master', 'stable', 'dev', 'beta'];
