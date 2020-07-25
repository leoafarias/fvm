import 'package:fvm/constants.dart';

import 'package:fvm/flutter/flutter_releases.dart';

// git clone --mirror https://github.com/flutter/flutter.git ~/gitcaches/flutter.reference
// git clone --reference ~/gitcaches/flutter.reference https://github.com/flutter/flutter.git

String release = '1.17.4';
String channel = 'beta';
String channelVersion;

void cleanup() {
  //TODO: Move this to another directory for testing
  // final fvmHomeDir = Directory(fvmHome);
  // if (fvmHomeDir.existsSync()) {
  //   fvmHomeDir.deleteSync(recursive: true);
  // }

  if (kProjectFvmDir.existsSync()) {
    kProjectFvmDir.deleteSync(recursive: true);
  }
}

void fvmTearDownAll() {
  cleanup();
}

void fvmSetUpAll() async {
  // Looks just like Teardown rightnow bu
  // will probalby change. Just to guarantee a clean run
  cleanup();
  final releases = await getReleases();
  channelVersion = releases.channels[channel].version;
}
