import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/utils/config_utils.dart';

void cleanup() async {
  final fvmHomeDir = Directory(fvmHome);
  if (await fvmHomeDir.exists()) {
    await fvmHomeDir.delete(recursive: true);
  }
  ConfigUtils().removeConfig();
  kProjectFvmDir.deleteSync(recursive: true);
}

void fvmTearDownAll() async {
  cleanup();
}

void fvmSetUpAll() async {
  // Looks just like Teardown rightnow bu
  // will probalby change. Just to guarantee a clean run
  cleanup();
}
