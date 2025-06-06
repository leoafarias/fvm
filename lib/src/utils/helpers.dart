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

/// Checks if [name] is a valid Flutter release channel.
bool isFlutterChannel(String name) {
  return kFlutterChannels.contains(name);
}

/// Converts Flutter versions and channels to comparable semver strings.
/// Assigns weights: git commits (500.0.0), master (400.0.0), stable (300.0.0),
/// beta (200.0.0), dev (100.0.0), invalid (0.0.0).
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
    // Validate version format - throws if invalid
    final _ = Version.parse(version);
  } on Exception {
    if (isCustom) {
      return '400.0.0';
    }

    return '0.0.0';
  }

  return version;
}

/// Formats a DateTime as "Month Day, Year" (e.g., "Jan 15, 2024").
String friendlyDate(DateTime dateTime) {
  return formatDate(dateTime, [M, ' ', d, ', ', yyyy]);
}

/// Returns true if running inside Visual Studio Code.
bool isVsCode() => Platform.environment['TERM_PROGRAM'] == 'vscode';

/// Parsed Flutter version information from `flutter --version` output.
class FlutterVersionOutput {
  /// The Flutter SDK version (e.g., "3.15.0").
  final String? flutterVersion;

  /// The Flutter release channel (e.g., "stable", "beta", "dev").
  final String? channel;

  /// The Dart SDK version (e.g., "3.2.0").
  final String? dartVersion;

  /// The Dart build version including build metadata (e.g., "3.2.0-134.1.beta").
  final String? dartBuildVersion;

  /// The Flutter framework Git revision hash.
  final String? frameworkRevision;

  /// The Flutter engine Git revision hash.
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

/// Parses Flutter version output from `flutter --version` command.
///
/// Example input formats:
/// ```
/// Flutter 3.15.0-15.1.pre • channel beta • https://github.com/flutter/flutter.git
/// Framework • revision b2ec15bfa3 (5 days ago) • 2023-09-14 15:31:44 -0500
/// Engine • revision 5c86194494
/// Tools • Dart 3.2.0 (build 3.2.0-134.1.beta) • DevTools 2.27.0
/// ```
///
/// ```
/// Flutter 3.10.5 • channel stable • https://github.com/flutter/flutter.git
/// Framework • revision 796c8ef792 (3 months ago) • 2023-06-13 15:51:02 -0700
/// Engine • revision 45f6e00911
/// Tools • Dart 3.0.5 • DevTools 2.23.1
/// ```
///
/// Returns a [FlutterVersionOutput] object with parsed version information.
/// Throws [FormatException] if the content cannot be parsed.
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

/// Extracts Dart version from `dart --version` output.
String extractDartVersionOutput(String input) {
  final RegExp regExp = RegExp(r'Dart SDK version: (\S+)');
  final match = regExp.firstMatch(input);
  if (match != null) {
    return match.group(1)!.trim();
  }
  throw FormatException(
    'No Dart version found in the input string. \n\n $input',
  );
}

/// Validates if a URL is a valid Git repository URL.
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

/// Converts string to boolean. Returns null for invalid values.
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

/// Formats bytes into human-readable format (e.g., "1.5 GB").
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

/// Calculates total size of a directory recursively.
Future<int> getDirectorySize(Directory dir) async {
  int total = 0;

  await for (FileSystemEntity entity in dir.list(recursive: true)) {
    if (entity is File) {
      total += await entity.length();
    }
  }

  return total;
}

/// Calculates total size of all cached Flutter versions in parallel.
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

/// Updates environment variables by prepending paths to PATH.
Map<String, String> updateEnvironmentVariables(
  List<String> paths,
  Map<String, String> env,
) {
  // Remove duplicates
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
