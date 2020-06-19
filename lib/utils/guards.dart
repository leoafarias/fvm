// Checks if its flutter project
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/helpers.dart';

/// Guards
class Guards {
  /// Checks if its on the root of a Flutter project
  static void isFlutterProject() {
    final isFlutter = kLocalProjectPubspec.existsSync();
    if (!isFlutter) {
      throw Exception('Run this FVM command at the root of a Flutter project');
    }
  }

  /// Check if Git is installed
  static void isGitInstalled() {
    try {
      Process.runSync('git', ['--version']);
    } on ProcessException {
      throw Exception(
          'You need Git Installed to run fvm. Go to https://git-scm.com/downloads');
    }
  }

  /// Make sure version is valid
  static Future<void> isFlutterVersion(String version) async {
    // Check if its a channel
    if (isFlutterChannel(version)) return;
    // Check if ts a version
    final flutterVersion = await inferFlutterVersion(version);
    if (flutterVersion == null) {
      throw ExceptionNotValidVersion(
          '"$version" is not a valid Flutter SDK version');
    }
  }
}
