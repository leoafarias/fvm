import 'dart:async';
import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:version/version.dart';

Directory versionCacheDir(String version) {
  return Directory(join(kFvmCacheDir.path, version));
}

/// Checks if path is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

/// Moves assets from theme directory into brand-app
Future<void> createLink(Link source, FileSystemEntity target) async {
  try {
    if (await source.exists()) {
      await source.delete();
    }
    await source.create(target.path);
  } on FileSystemException {
    if (Platform.isWindows) {
      throw Exception(
          'On Windows FVM requires to run in developer mode or as an administrator');
    }
  } on Exception {
    throw Exception('Sorry could not link ${target.path}');
  }
}

Map<String, String> updateFlutterEnvVariables(String execPath) {
  return _updateEnvVariables('flutter', execPath);
}

Map<String, String> updateDartEnvVariables(String execPath) {
  return _updateEnvVariables('dart', execPath);
}

Map<String, String> _updateEnvVariables(
  String key,
  String execPath,
) {
  assert(execPath != null);

  /// Remove exec path that does not match
  final pathEnvList = envVars['PATH']
      .split(':')
      .where((e) => '$e/$key' != whichSync(key))
      .toList();

  final newEnv = pathEnvList.join(':');

  return Map<String, String>.from(envVars)
    ..addAll({'PATH': '$newEnv:$execPath'});
}

// Assigns weight to [version] for proper comparison
Version assignVersionWeight(String version) {
  /// Assign version number to continue to work with semver
  switch (version) {
    case 'master':
      version = '400';
      break;
    case 'stable':
      version = '300';
      break;
    case 'beta':
      version = '200';
      break;
    case 'dev':
      version = '100';
      break;
    default:
  }

  if (version.contains('v')) {
    version = version.replaceFirst('v', '');
  }

  return Version.parse(version);
}
