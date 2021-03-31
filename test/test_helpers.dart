import 'dart:io';
import 'dart:math';

import 'package:fvm/constants.dart';
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:path/path.dart';

// git clone --mirror https://github.com/flutter/flutter.git ~/gitcaches/flutter.git
// git clone --reference ~/gitcaches/flutter.git https://github.com/flutter/flutter.git
// git remote update

String release = '1.17.4';
const channel = 'beta';
String channelVersion;

final kTestAssetsDir =
    Directory(join(kWorkingDirectory.path, 'test', 'support_assets'));
final kFlutterAppDir = Directory(join(kTestAssetsDir.path, 'flutter_app'));
final kDartPackageDir = Directory(join(kTestAssetsDir.path, 'dart_package'));
final kEmptyDir = Directory(join(kTestAssetsDir.path, 'empty_folder'));

Future<ValidVersion> getRandomFlutterVersion() async {
  final payload = await fetchFlutterReleases();
  final release = payload.releases[Random().nextInt(payload.releases.length)];
  return ValidVersion(release.version);
}

void cleanup() {
  // Remove all versions
  if (kFvmCacheDir.existsSync()) {
    final cacheDirList = kFvmCacheDir.listSync(recursive: true);
    for (var dir in cacheDirList) {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
  }
  // Remove fvm config from test projects

  final directoryList = kTestAssetsDir.listSync(recursive: true);
  for (var dir in directoryList) {
    final fvmDir = Directory(join(dir.path, '.fvm'));
    if (fvmDir.existsSync()) {
      fvmDir.deleteSync(recursive: true);
    }
  }
}

void fvmTearDownAll() {
  // cleanup();
}

void fvmSetUpAll() async {
  cleanup();
}
