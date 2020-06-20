// Checks if its flutter project
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/utils/git.dart';

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
      runGit(['--version']);
    } on ProcessException {
      throw Exception(
          'You need Git Installed to run fvm. Go to https://git-scm.com/downloads');
    }
  }
}
