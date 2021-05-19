import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fvm/constants.dart';
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

// git clone --mirror https://github.com/flutter/flutter.git ~/gitcaches/flutter.git
// git clone --reference ~/gitcaches/flutter.git https://github.com/flutter/flutter.git
// git remote update

String release = '1.17.4';
const channel = 'beta';
const gitHash = 'f4c74a6ec3';
String? channelVersion;

Directory getFvmTestDir(Key key) {
  return Directory(join(kUserHome, 'fvmTest', key.key));
}

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
  if (ctx.cacheDir.existsSync()) {
    final cacheDirList = ctx.cacheDir.listSync(recursive: true);
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

class Key {
  final String key;
  const Key(this.key);
}

@isTest
void testWithContext(
  String description,
  Key key,
  void Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  List<String>? tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  return test(
    description,
    () async {
      return ctx.run(
        name: key.key,
        fvmDir: getFvmTestDir(key),
        body: body,
      );
    },
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
    testOn: testOn,
  );
}

void fvmTearDownAll() {
  // cleanup();
}

void fvmSetUpAll() async {
  cleanup();
}
