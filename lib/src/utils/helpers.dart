import 'dart:io';

import 'package:date_format/date_format.dart';
import 'package:fvm/src/utils/git_utils.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../constants.dart';
import 'logger.dart';

/// Checks if [name] is a channel
@Deprecated('kFlutterVChannels.contains directly')
bool checkIsChannel(String name) {
  return kFlutterChannels.contains(name);
}

Map<String, String> updateEnvironmentVariables(
  List<String> paths,
  Map<String, String> env,
) {
  logger.detail('Starting to update environment variables...');

  final updatedEnvironment = Map<String, String>.from(env);

  final envPath = env['PATH'] ?? '';

  final separator = Platform.isWindows ? ';' : ':';

  updatedEnvironment['PATH'] = paths.join(separator) + separator + envPath;

  return updatedEnvironment;
}

/// Assigns weight to [version] to channels for comparison
/// Returns a weight for all versions and channels
String assignVersionWeight(String version) {
  /// Assign version number to continue to work with semver
  if (isGitCommit(version)) {
    version = '500.0.0';
  } else {
    switch (version) {
      case 'master':
        version = '400.0.0';
        break;
      case 'stable':
        version = '300.0.0';
        break;
      case 'beta':
        version = '200.0.0';
        break;
      case 'dev':
        version = '100.0.0';
        break;
      default:
    }
  }

  if (version.contains('v')) {
    version = version.replaceFirst('v', '');
  }

  try {
    Version.parse(version);
  } on Exception {
    logger.warn('Version $version is not a valid semver');
    return '0.0.0';
  }

  return version;
}

String friendlyDate(DateTime dateTime) {
  return formatDate(dateTime, [M, ' ', d, ', ', yyyy]);
}

bool isVsCode() {
  return Platform.environment['TERM_PROGRAM'] == 'vscode';
}
