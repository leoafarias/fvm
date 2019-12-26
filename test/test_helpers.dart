import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/utils/config_utils.dart';

void fvmTearDownAll() async {
  final fvmHomeDir = Directory(fvmHome);
  if (await fvmHomeDir.exists()) {
    await fvmHomeDir.delete(recursive: true);
  }
  await ConfigUtils().removeConfig();
}

void fvmSetUpAll() async {
  // Looks just like Teardown rightnow bu
  // will probalby change. Just to guarantee a clean run
  final fvmHomeDir = Directory(fvmHome);
  if (await fvmHomeDir.exists()) {
    await fvmHomeDir.delete(recursive: true);
  }
  await ConfigUtils().removeConfig();
}
