import 'dart:io';

import 'package:fvm/src/utils/is_git_commit.dart';

import '../../constants.dart';
import '../../exceptions.dart';
import '../services/context.dart';
import 'logger.dart';

/// Checks if [name] is a channel
@Deprecated('kFlutterVChannels.contains directly')
bool checkIsChannel(String name) {
  return kFlutterChannels.contains(name);
}

/// Returns true if [path] is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

/// Runs which command

/// Creates a symlink from [source] to the [target]
void createLink(Link source, Directory target) {
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
