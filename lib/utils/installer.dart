import 'package:fvm/exceptions.dart';
import 'package:fvm/flutter/flutter_tools.dart';

import 'package:fvm/utils/pretty_print.dart';

import 'pretty_print.dart';

Future<void> installRelease(String version, {bool skipSetup = false}) async {
  if (version == null) {
    throw ExceptionMissingChannelVersion();
  }

  // If it's installed correctly just return and use cached
  if (await isInstalledCorrectly(version)) {
    PrettyPrint.success('Version: $version - already installed.');
    return;
  }

  PrettyPrint.success('Installing version: $version:');

  await gitCloneCmd(version);

  // Skips Flutter sdk setup
  if (skipSetup) return;
  PrettyPrint.success('Setting up Flutter sdk');
  PrettyPrint.info('If you want to skip this next time use "--skip-setup"');
  await setupFlutterSdk(version);
}
