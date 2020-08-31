import 'dart:async';

import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/src/utils/confirm.dart';
import 'package:fvm/src/local_versions/local_version.repo.dart';
import 'package:fvm/src/utils/pretty_print.dart';

import 'package:fvm/src/utils/installer.dart';

import 'pretty_print.dart';

/// Checks if path is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

/// Checks if version is installed, and installs or exits
Future<void> checkAndInstallVersion(String version) async {
  if (await LocalVersionRepo().isInstalled(version)) return null;
  PrettyPrint.info('Flutter $version is not installed.');

  // Install if input is confirmed
  if (await confirm('Would you like to install it?')) {
    await installRelease(version);
  } else {
    return;
  }
}

/// Moves assets from theme directory into brand-app
Future<void> createLink(Link source, FileSystemEntity target) async {
  try {
    if (await source.exists()) {
      await source.delete();
    }
    await source.create(target.path);
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
