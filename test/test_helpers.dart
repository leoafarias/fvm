import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/utils/config_utils.dart';

void cleanup() {
  final fvmHomeDir = Directory(fvmHome);
  if (fvmHomeDir.existsSync()) {
    fvmHomeDir.deleteSync(recursive: true);
  }
  ConfigUtils().removeConfig();
  if (kProjectFvmDir.existsSync()) {
    kProjectFvmDir.deleteSync(recursive: true);
  }
}

void fvmTearDownAll() {
  cleanup();
}

void fvmSetUpAll() {
  // Looks just like Teardown rightnow bu
  // will probalby change. Just to guarantee a clean run
  cleanup();
}
