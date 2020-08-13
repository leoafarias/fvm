import 'dart:async';

import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/confirm.dart';
import 'package:fvm/utils/installed_versions.dart';
import 'package:fvm/utils/pretty_print.dart';

import 'package:fvm/utils/installer.dart';

import 'pretty_print.dart';

/// Checks if path is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

/// Checks if version is installed, and installs or exits
Future<void> checkAndInstallVersion(String version) async {
  if (await isInstalledVersion(version)) return null;
  PrettyPrint.info('Flutter $version is not installed.');

  // Install if input is confirmed
  if (await confirm('Would you like to install it?')) {
    await installRelease(version);
  } else {
    // If do not install exist
    exit(0);
  }
}

/// Moves assets from theme directory into brand-app
void createLink(
  Link source,
  FileSystemEntity target,
) async {
  try {
    if (source.existsSync()) {
      source.deleteSync();
    }
    source.createSync(target.path);
  } on Exception catch (err) {
    logVerboseError(err);
    throw Exception('Sorry could not link ${target.path}');
  }
}

String camelCase(String subject) {
  final _splittedString = subject.split('_');

  if (_splittedString.isEmpty) return '';

  final _firstWord = _splittedString[0].toLowerCase();
  final _restWords = _splittedString.sublist(1).map(capitalize).toList();

  return _firstWord + _restWords.join('');
}

String capitalize(String word) {
  return '${word[0].toUpperCase()}${word.substring(1)}';
}

class DirStat {
  final int fileNum;
  final int totalSize;
  DirStat({this.fileNum, this.totalSize});
}

Future<DirStat> dirStat(String dirPath) async {
  var fileNum = 0;
  var totalSize = 0;
  var dir = Directory(dirPath);
  try {
    if (await dir.exists()) {
      await dir
          .list(recursive: true, followLinks: false)
          .forEach((FileSystemEntity entity) {
        if (entity is File) {
          fileNum++;
          totalSize += entity.lengthSync();
        }
      });
    }
  } catch (e) {
    print(e.toString());
  }

  return DirStat(fileNum: fileNum, totalSize: totalSize);
}
