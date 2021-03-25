import 'package:console/console.dart';
import 'package:fvm/fvm.dart';

import 'package:fvm/src/models/flutter_app_model.dart';
import 'package:fvm/src/utils/logger.dart';

void printVersions(CacheVersion version, FlutterApp project) {
  var printVersion = version.name;

  if (project != null && project.pinnedVersion == version.name) {
    printVersion = '$printVersion ${Icon.HEAVY_CHECKMARK}';
  }
  if (CacheService.isGlobal(version)) {
    printVersion = '$printVersion (global)';
  }
  FvmLogger.info(printVersion);
}
