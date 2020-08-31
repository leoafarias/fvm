import 'package:fvm/src/flutter_tools/flutter_tools.dart';

import 'package:fvm/src/releases_api/releases_client.dart';
import 'package:fvm/src/utils/installer.dart';

export 'package:fvm/src/runner.dart';
export 'package:fvm/src/local_versions/local_version.model.dart';
export 'package:fvm/src/local_versions/local_version.repo.dart';
export 'package:fvm/src/releases_api/models/flutter_releases.model.dart';
export 'package:fvm/src/flutter_project/flutter_project.model.dart';
export 'package:fvm/src/flutter_project/flutter_project.repo.dart';
export 'package:fvm/src/releases_api/models/release.model.dart';
export 'package:fvm/src/releases_api/models/channels.model.dart';

// FVM API for consumption from GUI & other tools
class FVM {
  // Flutter SDK
  static final install = installRelease;
  static final setup = setupFlutterSdk;
  static final upgrade = upgradeFlutterChannel;
  static final noAnalytics = disableTracking;

  // Interaction with releases api
  static final getFlutterReleases = fetchFlutterReleases;
}
