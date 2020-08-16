import 'package:fvm/src/flutter_project/project_config.repo.dart';
import 'package:fvm/src/flutter_tools/flutter_tools.dart';
import 'package:fvm/src/local_versions/local_version.repo.dart';
import 'package:fvm/src/local_versions/local_versions_tools.dart';
import 'package:fvm/src/releases_api/releases_client.dart';
import 'package:fvm/src/utils/installer.dart';

export 'package:fvm/src/cli/runner.dart';
export 'package:fvm/src/releases_api/models/flutter_releases.model.dart';
export 'package:fvm/src/local_versions/local_version.model.dart';
export 'package:fvm/src/releases_api/models/release.model.dart';
export 'package:fvm/src/releases_api/models/channels.model.dart';

// FVM API for consumption from GUI & other tools
class FVM {
  // Installing flutter sdk
  static final install = installRelease;
  static final setup = setupFlutterSdk;

  // Interaction with local versions
  static final remove = removeRelease;
  static final getLocalVersions = LocalVersionRepo.getAll;

  // Interaction with releases api
  static final getFlutterReleases = fetchFlutterReleases;

  // Flutter projects
  static final getProjectConfig = readProjectConfig;
}
