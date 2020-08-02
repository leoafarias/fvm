library fvm_api;

import 'package:fvm/flutter/flutter_releases.dart' as releases;
import 'package:fvm/utils/cache_dir.dart' as cache_dir;
import 'package:fvm/utils/installed_release.dart' as installed_release;

// TODO: How to create a public protected interface
class FVMAPI {
  static final fetchFlutterReleases = releases.fetchFlutterReleases;
  static final getInstalledReleases = installed_release.getInstalledReleases;
  static final getCacheDirectory = cache_dir.getCacheDirectory;
}
