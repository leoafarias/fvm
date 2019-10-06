import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';

/// Returns true if it's a valid Flutter version number
Future<bool> isValidFlutterVersion(String version) async {
  return (await listSdkVersions()).contains('v$version');
}

/// Returns true if it's a valid Flutter channel
bool isValidFlutterChannel(String channel) {
  return kFlutterChannels.contains(channel);
}

/// Returns true it's a valid installed version
Future<bool> isValidFlutterInstall(String version) async {
  return (await flutterListInstalledSdks()).contains(version);
}
