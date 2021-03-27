// import 'package:fvm/src/services/flutter_tools.dart';

// import 'package:fvm/src/services/releases_service/releases_client.dart';
// import 'package:fvm/src/utils/logger.dart';

// import 'package:fvm/src/workflows/flutter_setup.workflow.dart';
// import 'package:fvm/src/workflows/install_version.workflow.dart';
// import 'package:fvm/src/workflows/remove_version.workflow.dart';

export 'package:fvm/src/runner.dart';
export 'package:fvm/src/models/cache_version_model.dart';
export 'package:fvm/src/services/cache_service.dart';
export 'package:fvm/src/services/releases_service/models/flutter_releases.model.dart';
export 'package:fvm/src/models/flutter_app_model.dart';
export 'package:fvm/src/services/flutter_app_service.dart';
export 'package:fvm/src/services/releases_service/models/release.model.dart';
export 'package:fvm/src/services/releases_service/models/channels.model.dart';
export 'package:fvm/src/utils/settings.dart';

// FVM API for consumption from GUI & other tools
// class FVMClient {
//   // Flutter SDK
//   static final install = (String versionName) =>
//       installWorkflow(versionName, skipConfirmation: true);
//   static final remove = removeWorkflow;
//   static final setup = flutterSetupWorkflow;
//   static final upgrade = upgradeChannel;
//   static final noAnalytics = disableTracking;
//   static final console = consoleController;

//   // Interaction with releases api
//   static final getFlutterReleases = fetchFlutterReleases;
// }
