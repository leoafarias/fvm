import 'dart:async';
import 'dart:io';

import 'package:cli_notify/cli_notify.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../services/context.dart';
import '../version.dart';
import 'logger.dart';

/// Checks if [name] is a channel
bool checkIsChannel(String name) {
  return kFlutterChannels.contains(name);
}

/// Checks if [name] is a channel with a release
/// master channels do not have releases
bool checkIsReleaseChannel(String name) {
  return kFlutterChannels.contains(name) && name != 'master';
}

/// Checks if [name] is a short hash of a specific framework commit.
/// This hash is also shown in the `flutter --version` command.
bool checkIsGitHash(String name) {
  final shortHash = RegExp('^[a-f0-9]{10}\$').hasMatch(name);
  final hash = RegExp('^[a-f0-9]{40}\$').hasMatch(name);
  return shortHash || hash;
}

/// Returns a cache [Directory] for a [version]
Directory versionCacheDir(String version) {
  return Directory(join(ctx.cacheDir.path, version));
}

/// Returns true if [path] is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

/// Get the parent directory path of a [filePath]
Future<String> getParentDirPath(String filePath) async {
  final file = File(filePath);

  return file.parent.path;
}

/// Creates a symlink from [source] to the [target]
Future<void> createLink(Link source, FileSystemEntity target) async {
  try {
    // Check if needs to do anything

    final sourceExists = await source.exists();
    if (sourceExists && await source.target() == target.path) {
      logger.trace('Link is setup correctly');
      return;
    }

    if (sourceExists) {
      await source.delete();
    }

    await source.create(
      target.path,
      recursive: true,
    );
  } on FileSystemException catch (e) {
    logger.trace(e.toString());

    var message = '';
    if (Platform.isWindows) {
      message = 'On Windows FVM requires to run as an administrator '
          'or turn on developer mode: https://bit.ly/3vxRr2M';
    }

    throw FvmUsageException(
      "Seems you don't have the required permissions on ${ctx.fvmHome.path}"
      ' $message',
    );
  }
}

/// Returns updated environment for Flutter with [execPath]
Map<String, String> updateFlutterEnvVariables(String binPath) {
  return _updateEnvVariables('flutter', binPath);
}

/// Returns updated environment for Dark with [binPath]
Map<String, String> updateDartEnvVariables(String binPath) {
  return _updateEnvVariables('dart', binPath);
}

Map<String, String> _updateEnvVariables(
  String key,
  String binPath,
) {
  final envPath = kEnvVars['PATH'] ?? '';

  /// Remove exec path that does not match
  final pathEnvList = envPath
      .split(':')
      .where(
        (e) => '$e/$key' != whichSync(key),
      )
      .toList();

  final newEnv = pathEnvList.join(':');

  return Map<String, String>.from(kEnvVars)
    ..addAll({'PATH': '$newEnv:$binPath'});
}

/// Compares a [version] against [other]
/// returns negative if [version] is ordered before
/// positive if [version] is ordered after
/// 0 if its the same
int compareSemver(String version, String other) {
  final regExp = RegExp(
    r"(?<Major>0|(?:[1-9]\d*))(?:\.(?<Minor>0|(?:[1-9]\d*))(?:\.(?<Patch>0|(?:[1-9]\d*)))?(?:\-(?<PreRelease>[0-9A-Z\.-]+))?(?:\+(?<Meta>[0-9A-Z\.-]+))?)?",
  );
  try {
    if (regExp.hasMatch(version) && regExp.hasMatch(other)) {
      final versionMatches = regExp.firstMatch(version);
      final otherMatches = regExp.firstMatch(other);

      var result = 0;

      if (versionMatches == null || otherMatches == null) {
        return result;
      }

      for (var idx = 1; idx < versionMatches.groupCount; idx++) {
        final versionMatch = versionMatches.group(idx) ?? '';
        final otherMatch = otherMatches.group(idx) ?? '';
        final versionNumber = int.tryParse(versionMatch);
        final otherNumber = int.tryParse(otherMatch);
        if (versionMatch != otherMatch) {
          if (versionNumber == null || otherNumber == null) {
            result = versionMatch.compareTo(otherMatch);
          } else {
            result = versionNumber.compareTo(otherNumber);
          }
          break;
        }
      }

      return result;
    }

    return 0;
  } on Exception catch (err) {
    print(err.toString());
    return 0;
  }
}

/// Assigns weight to [version] to channels for comparison
/// Returns a weight for all versions and channels
String assignVersionWeight(String version) {
  /// Assign version number to continue to work with semver
  if (checkIsGitHash(version)) {
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

  return version;
}

/// Check if there is an update for FVM
Future<void> checkForFvmUpdate() async {
  await Notify(
    packageName: 'fvm',
    currentVersion: packageVersion,
  ).update();
}

/// Check if fvm is in cache directory
bool isFvmInstalledGlobally() {
  /// Segment of the path where Pub caches global packages
  final pubCacheSegment = Platform.isWindows ? "Pub\Cache" : ".pub-cache";
  logger.trace(Platform.script.path);
  return Platform.script.path.contains(pubCacheSegment);
}

/// Check if command needs to be run detached
bool shouldRunDetached(List<String> args) {
  /// List of Flutter/Dart commands that need to run detached to avoid fvm errors.
  const shouldDetachCommands = [
    'pub cache repair',
    'pub cache clean',
  ];
  final argString = args.join(' ');
  final shouldDetach = shouldDetachCommands.any(argString.contains);
  return shouldDetach && isFvmInstalledGlobally();
}
