import 'dart:io';
import 'dart:math' as math;

import 'package:dart_mappable/dart_mappable.dart';
import 'package:date_format/date_format.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../models/cache_flutter_version_model.dart';
import 'constants.dart';
import 'extensions.dart';
import 'git_utils.dart';

/// Checks if [name] is a channel

bool isFlutterChannel(String name) {
  return kFlutterChannels.contains(name);
}

/// Assigns weight to [version] to channels for comparison
/// Returns a weight for all versions and channels
String assignVersionWeight(String version) {
  /// Assign version number to continue to work with semver
  if (isPossibleGitCommit(version)) {
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

  bool isCustom = version.contains('custom_');

  if (isCustom) {
    version = version.replaceFirst('custom_', '');
  }

  try {
    // Checking to throw an issue if it cannot parse
    // ignore: avoid-unused-instances
    Version.parse(version);
  } on Exception {
    if (isCustom) {
      return '400.0.0';
    }

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
  final String? frameworkRevision;
  final String? engineRevision;

  const FlutterVersionOutput({
    this.flutterVersion,
    this.channel,
    this.dartVersion,
    this.dartBuildVersion,
    this.frameworkRevision,
    this.engineRevision,
  });

  @override
  String toString() {
    return 'FlutterVersionOutput(flutterVersion: $flutterVersion, channel: $channel, dartVersion: $dartVersion, dartBuildVersion: $dartBuildVersion, frameworkRevision: $frameworkRevision, engineRevision: $engineRevision)';
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
  final channelRegex = RegExp(r' channel ([^\s•]+)');
  final dartRegex = RegExp(r'Dart (\S+)(?: \(build (\S+)\))?');
  final frameworkRegex = RegExp(r'Framework • revision (\w+)');
  final engineRegex = RegExp(r'Engine • revision (\w+)');

  final flutterMatch = flutterRegex.firstMatch(filteredContent);
  final channelMatch = channelRegex.firstMatch(filteredContent);
  final dartMatch = dartRegex.firstMatch(filteredContent);
  final frameworkMatch = frameworkRegex.firstMatch(filteredContent);
  final engineMatch = engineRegex.firstMatch(filteredContent);

  if (flutterMatch == null) {
    throw FormatException('Unable to parse Flutter version.');
  }

  if (dartMatch == null) {
    throw FormatException('Unable to parse Dart version.');
  }

  final channel = channelMatch?.group(1);
  if (channel == null || !isFlutterChannel(channel)) {
    throw FormatException('Unable to parse Flutter channel.');
  }

  return FlutterVersionOutput(
    flutterVersion: flutterMatch.group(1)!,
    channel: channel,
    dartVersion: dartMatch.group(1)!,
    dartBuildVersion: dartMatch.group(2) ?? dartMatch.group(1)!,
    frameworkRevision: frameworkMatch?.group(1),
    engineRevision: engineMatch?.group(1),
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

String formatFriendlyBytes(int bytes, [int decimals = 2]) {
  if (bytes <= 0) return '0 B';

  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB'];
  final int suffixIndex = math.min(
    (math.log(bytes) / math.log(1024)).floor(),
    suffixes.length - 1,
  );

  final num scaledValue = bytes / math.pow(1024, suffixIndex);

  return '${scaledValue.toStringAsFixed(decimals)} ${suffixes[suffixIndex]}';
}

Future<int> getDirectorySize(Directory dir) async {
  int total = 0;

  // Using async/await to asynchronously handle the file system's directories and files
  await for (FileSystemEntity entity in dir.list(recursive: true)) {
    if (entity is File) {
      // Accumulate file size
      total += await entity.length();
    }
  }

  return total;
}

Future<int> getFullDirectorySize(List<CacheFlutterVersion> versions) async {
  if (versions.isEmpty) return 0;

  try {
    // Process all directories in parallel with error handling for each
    final sizes = await Future.wait(
      versions.map((version) async {
        try {
          return await getDirectorySize(version.directory.dir);
        } catch (e) {
          // Log error but continue with zero for this directory
          print('Error calculating size for ${version.name}: $e');

          return 0;
        }
      }),
    );

    // Sum all sizes in one operation
    return sizes.fold<int>(0, (sum, size) => sum + size);
  } catch (e) {
    // Fallback if parallel execution fails
    print('Error calculating full directory size: $e');

    return 0;
  }
}

Map<String, String> updateEnvironmentVariables(
  List<String> paths,
  Map<String, String> env,
) {
  // Remove any values that are similar
  // within the list of paths.
  paths = paths.toSet().toList();

  final updatedEnvironment = Map<String, String>.from(env);

  final envPath = env['PATH'] ?? '';

  final separator = Platform.isWindows ? ';' : ':';

  updatedEnvironment['PATH'] = paths.join(separator) + separator + envPath;

  return updatedEnvironment;
}

const skipCopyWith = GenerateMethods.decode |
    GenerateMethods.encode |
    GenerateMethods.stringify |
    GenerateMethods.equals;

/// Recursively searches for a directory and returns the first valid candidate.
///
/// This function will traverse up the directory hierarchy until it finds a valid
/// candidate or reaches the root directory.
///
/// If no valid candidate is found, it will return the result of calling the
T? lookUpDirectoryAncestor<T>({
  required Directory directory,
  required T? Function(Directory) validate,
  void Function(String)? debugPrinter,
}) {
  // ignore: no-empty-block
  debugPrinter ??= (String message) {};
  debugPrinter('Looking up directory: ${directory.path}');
  // Check if the current directory is the root
  final isRootDir = p.rootPrefix(directory.path) == directory.path;

  final result = validate(directory);

  if (result != null) {
    debugPrinter('Found valid candidate: ${directory.path}');

    return result;
  }

  // If we reached the root directory, return the fallback
  if (isRootDir) {
    debugPrinter('No valid directory found');

    return null;
  }

  // Otherwise, recursively search the parent directory
  return lookUpDirectoryAncestor(
    directory: directory.parent,
    validate: validate,
  );
}
