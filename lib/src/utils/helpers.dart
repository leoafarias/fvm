import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../services/context.dart';
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

/// Creates a symlink from [source] to the [target]
Future<void> createLink(Link source, FileSystemEntity target) async {
  try {
    if (await source.exists()) {
      await source.delete();
    }
    await source.create(target.path);
  } on FileSystemException catch (e) {
    logger.trace(e.message);
    if (Platform.isWindows) {
      throw const FvmInternalError(
        'On Windows FVM requires to run in'
        'developer mode or as an administrator',
      );
    }
  }
}

/// Returns updated environment for Flutter with [execPath]
Map<String, String> updateFlutterEnvVariables(String execPath) {
  return _updateEnvVariables('flutter', execPath);
}

/// Returns updated environment for Dark with [execPath]
Map<String, String> updateDartEnvVariables(String execPath) {
  return _updateEnvVariables('dart', execPath);
}

Map<String, String> _updateEnvVariables(
  String key,
  String execPath,
) {
  assert(execPath != null);

  /// Remove exec path that does not match
  final pathEnvList = kEnvVars['PATH']
      .split(':')
      .where((e) => '$e/$key' != whichSync(key))
      .toList();

  final newEnv = pathEnvList.join(':');

  return Map<String, String>.from(kEnvVars)
    ..addAll({'PATH': '$newEnv:$execPath'});
}

/// Assigns weight to [version] to channels for comparison
/// Returns a weight for all versions and channels
Version assignVersionWeight(String version) {
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

  return Version.parse(version);
}
