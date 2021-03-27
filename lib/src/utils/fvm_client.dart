import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/services/git_tools.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:fvm/src/workflows/remove_version.workflow.dart';
import 'package:fvm/src/workflows/use_version.workflow.dart';

/// Used for exposing methods used by other clients or Sidekick

class FVMClient {
  // Flutter SDK
  static final install = (String versionName) =>
      ensureCacheWorkflow(versionName, skipConfirmation: true);
  static final remove = removeWorkflow;
  static final use = useVersionWorkflow;
  static final flutterTools = FlutterTools;
  static final gitTools = GitTools;
  static final console = consoleController;
  // Interaction with releases api
  static final getFlutterReleases = fetchFlutterReleases;
}
