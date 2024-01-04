import 'dart:io';

import 'package:date_format/date_format.dart';
import 'package:fvm/src/utils/git_utils.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../constants.dart';
import '../services/logger_service.dart';

/// Checks if [name] is a channel

bool isFlutterChannel(String name) {
  return kFlutterChannels.contains(name);
}

Map<String, String> updateEnvironmentVariables(
  List<String> paths,
  Map<String, String> env,
) {
  // Remove any values that are similar
  // within the list of paths.
  paths = paths.toSet().toList();

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

bool isVsCode() => Platform.environment['TERM_PROGRAM'] == 'vscode';

class FlutterVersionOutput {
  final String? flutterVersion;
  final String? channel;
  final String? dartVersion;
  final String? dartBuildVersion;

  const FlutterVersionOutput({
    this.flutterVersion,
    this.channel,
    this.dartVersion,
    this.dartBuildVersion,
  });

  @override
  String toString() {
    return 'FlutterVersionOutput(flutterVersion: $flutterVersion, channel: $channel, dartVersion: $dartVersion, dartBuildVersion: $dartBuildVersion)';
  }
}

// Parses Flutter version output
// EXAMPLE:1
// Flutter 3.15.0-15.1.pre • channel beta • https://github.com/flutter/flutter.git
// Framework • revision b2ec15bfa3 (5 days ago) • 2023-09-14 15:31:44 -0500
// Engine • revision 5c86194494
// Tools • Dart 3.2.0 (build 3.2.0-134.1.beta) • DevTools 2.27.0
// EXAMPLE:2
// Flutter 3.10.5 • channel stable • https://github.com/flutter/flutter.git
// Framework • revision 796c8ef792 (3 months ago) • 2023-06-13 15:51:02 -0700
// Engine • revision 45f6e00911
// Tools • Dart 3.0.5 • DevTools 2.23.1
// EXAMPLE:3
// Flutter 2.2.0 • channel stable • https://github.com/flutter/flutter.git
// Framework • revision b22742018b (2 years, 4 months ago) • 2021-05-14 19:12:57 -0700
// Engine • revision a9d88a4d18
// Tools • Dart 2.13.0
FlutterVersionOutput extractFlutterVersionOutput(String content) {
  final filteredContent = _extractFlutterInfoBlock(content);
  final flutterRegex = RegExp(r'Flutter (\S+)');
  final channelRegex = RegExp(r' channel (\w+)');
  final dartRegex = RegExp(r'Dart (\S+)');
  final dartBuildRegex = RegExp(r'Dart (\S+) \(build (\S+)\)');

  final flutterMatch = flutterRegex.firstMatch(filteredContent);
  final channelMatch = channelRegex.firstMatch(filteredContent);
  final dartMatch = dartRegex.firstMatch(filteredContent);
  final dartBuildMatch = dartBuildRegex.firstMatch(filteredContent);

  if (flutterMatch == null || dartMatch == null) {
    throw FormatException(
      'Unable to parse Flutter or Dart version from the provided content.',
    );
  }

  final dartVersion = dartMatch.group(1);

  final channel = channelMatch?.group(1);

  if (channel == null || !isFlutterChannel(channel)) {
    throw FormatException(
      'Unable to parse Flutter channel from the provided content.',
    );
  }

  return FlutterVersionOutput(
    flutterVersion: flutterMatch.group(1),
    channel: channel,
    dartVersion: dartVersion,
    dartBuildVersion: dartBuildMatch?.group(2) ?? dartVersion,
  );
}

String _extractFlutterInfoBlock(String content) {
  // Ignore anything before "Flutter
  final flutterInfoBlock = content.indexOf('Flutter');
  if (flutterInfoBlock == -1) {
    throw FormatException(
      'Unable to parse Flutter version from the provided content.',
    );
  }

  return content.substring(flutterInfoBlock);
}

String extractDartVersionOutput(String input) {
  // The updated regular expression to capture the full version string
  final RegExp regExp = RegExp(r'Dart SDK version: (\S+)');
  final match = regExp.firstMatch(input);
  if (match != null) {
    return match.group(1)!.trim(); // Returns the version number
  }
  throw FormatException(
    'No Dart version found in the input string. \n\n $input',
  );
}

bool isValidGitUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.scheme.isNotEmpty &&
        (uri.host.isNotEmpty || uri.path.isNotEmpty) &&
        uri.path.endsWith('.git');
  } catch (e) {
    return false;
  }
}

bool? stringToBool(String value) {
  final lowerCase = value.toLowerCase();
  if (lowerCase == 'true') {
    return true;
  }

  if (lowerCase == 'false') {
    return false;
  }

  return null;
}
