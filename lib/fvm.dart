import 'package:fvm/src/flutter_tools/flutter_tools.dart';

import 'package:fvm/src/releases_api/releases_client.dart';
import 'package:fvm/src/utils/logger.dart';

import 'package:fvm/src/workflows/flutter_setup.workflow.dart';
import 'package:fvm/src/workflows/install_version.workflow.dart';
import 'package:fvm/src/workflows/remove_version.workflow.dart';

export 'package:fvm/src/runner.dart';
export 'package:fvm/src/local_versions/local_version.model.dart';
export 'package:fvm/src/local_versions/local_version.repo.dart';
export 'package:fvm/src/releases_api/models/flutter_releases.model.dart';
export 'package:fvm/src/flutter_project/flutter_project.model.dart';
export 'package:fvm/src/flutter_project/flutter_project.repo.dart';
export 'package:fvm/src/releases_api/models/release.model.dart';
export 'package:fvm/src/releases_api/models/channels.model.dart';
export 'package:fvm/src/utils/settings.dart';

// FVM API for consumption from GUI & other tools
class FVM {
  // Flutter SDK
  static final install = installWorkflow;
  static final remove = removeWorkflow;
  static final setup = flutterSetupWorkflow;
  static final upgrade = upgradeFlutterChannel;
  static final noAnalytics = disableTracking;
  static final console = consoleController;

  // Interaction with releases api
  static final getFlutterReleases = fetchFlutterReleases;
}
