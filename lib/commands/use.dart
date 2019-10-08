import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';

/// Use an installed SDK version
class UseCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "use";
  final description = "Which Flutter SDK Version you would like to use";

  /// Constructor
  UseCommand();

  Future<void> run() async {
    final version = argResults.arguments[0];

    final isValidInstall = await isValidFlutterInstall(version);

    if (!isValidInstall) {
      throw Exception('Flutter SDK: $version is not installed');
    }

    final progress = logger.progress('Using $version');
    try {
      await linkProjectFlutterDir(version);
      finishProgress(progress);
    } on Exception {
      rethrow;
    }
  }
}
