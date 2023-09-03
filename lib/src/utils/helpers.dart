import 'dart:io';

import 'package:path/path.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../services/context.dart';
import 'logger.dart';

/// Checks if [name] is a channel
bool checkIsChannel(String name) {
  return kFlutterChannels.contains(name);
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
  return Directory(join(ctx.fvmVersionsDir.path, version));
}

/// Returns true if [path] is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

/// Runs which command

/// Creates a symlink from [source] to the [target]
void createLink(Link source, FileSystemEntity target) {
  try {
    // Check if needs to do anything

    final sourceExists = source.existsSync();
    if (sourceExists && source.targetSync() == target.path) {
      logger.detail('Link is setup correctly\n');
      return;
    }

    if (sourceExists) {
      source.deleteSync();
    }

    source.createSync(
      target.path,
      recursive: true,
    );
  } on FileSystemException catch (e) {
    logger.detail(e.toString());

    var message = '';
    if (Platform.isWindows) {
      message = 'On Windows FVM requires to run as an administrator '
          'or turn on developer mode: https://bit.ly/3vxRr2M';
    }

    throw FvmUsageException(
      "Seems you don't have the required permissions on ${ctx.fvmDir.path}"
      ' $message',
    );
  }
}

/// Get the parent directory path of a [filePath]
String getParentDirPath(String filePath) {
  final file = File(filePath);

  return file.parent.path;
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
    logger.detail(err.toString());
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

/// Check if fvm is in cache directory
bool isFvmInstalledGlobally() {
  /// Segment of the path where Pub caches global packages

  logger.detail(Platform.isWindows.toString());
  final pubCacheSegment = Platform.isWindows ? 'Pub/Cache' : ".pub-cache";
  logger.detail(Platform.script.path);
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

/// Returns map equality.
/// Copy from [Github](https://github.com/flutter/flutter/blob/f1875d570e/packages/flutter/lib/src/foundation/collections.dart#L80)
bool mapEquals<T, U>(Map<T, U>? a, Map<T, U>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) {
      return false;
    }
  }
  return true;
}

extension ListExtension<T> on Iterable<T> {
  /// Returns firstWhereOrNull
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
