import 'package:console/console.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/utils/logger.dart';

void printVersions(String version, FlutterProject project) {
  var printVersion = version;

  if (project != null && project.pinnedVersion == version) {
    printVersion = '$printVersion ${Icon.HEAVY_CHECKMARK}';
  }
  if (isGlobalVersion(version)) {
    printVersion = '$printVersion (global)';
  }
  FvmLogger.info(printVersion);
}
