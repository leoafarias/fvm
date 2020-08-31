import 'dart:io';
import 'dart:math';

import 'package:fvm/src/releases_api/releases_client.dart';
import 'package:path/path.dart';

// git clone --mirror https://github.com/flutter/flutter.git ~/gitcaches/flutter.reference
// git clone --reference ~/gitcaches/flutter.reference https://github.com/flutter/flutter.git
// git remote update

String release = '1.17.4';
String channel = 'beta';
String channelVersion;

final kTestAssetsDir =
    Directory(join(Directory.current.path, 'test', 'test_assets'));
final kFlutterAppDir = Directory(join(kTestAssetsDir.path, 'flutter_app'));
final kDartPackageDir = Directory(join(kTestAssetsDir.path, 'dart_package'));
final kEmptyDir = Directory(join(kTestAssetsDir.path, 'empty_folder'));

Future<String> getRandomFlutterVersion() async {
  final payload = await fetchFlutterReleases();
  final release = payload.releases[Random().nextInt(payload.releases.length)];
  return release.version;
}

void cleanup() {
  // Remove fvm config from test projects
  final directoryList = kTestAssetsDir.listSync(recursive: true);
  directoryList.forEach((dir) {
    final fvmDir = Directory(join(dir.path, '.fvm'));
    if (fvmDir.existsSync()) {
      fvmDir.deleteSync(recursive: true);
    }
  });
}

void fvmTearDownAll() {
  cleanup();
}

void fvmSetUpAll() async {
  cleanup();
  final releases = await fetchFlutterReleases();
  channelVersion = releases.channels[channel].version;
}
