import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/print.dart';

Future<void> installFlutterVersion(String version,
    {bool skipSetup = false}) async {
  if (version == null) {
    throw ExceptionMissingChannelVersion();
  }

  // If it's installed correctly just return and use cached
  if (isInstalledCorrectly(version)) {
    Print.success('Version: $version - already installed.');
    return;
  }

  Print.success('Installing Version: $version:');

  await gitCloneCmd(version);

  // Skips Flutter sdk setup
  if (skipSetup) return;
  Print.success('Setting up Flutter sdk');
  Print.info('If you want to skip this next time use "--skip-setup"');
  final flutterExec = getFlutterSdkExec(version: version);
  await flutterCmd(flutterExec, ['--version']);
}
