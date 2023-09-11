import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/logger.dart';

/// Returns true if [path] is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

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
      "Seems you don't have the required permissions on ${ctx.fvmDir}"
      ' $message',
    );
  }
}
