import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';
import 'package:fvm/utils/project_config.dart';
import 'package:fvm/utils/version_installer.dart';
import 'package:io/ansi.dart';

/// Use an installed SDK version
class UseCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'use';

  @override
  final description = 'Which Flutter SDK Version you would like to use';

  /// Constructor
  UseCommand();

  @override
  Future<void> run() async {
    // Check if it's Flutter project
    if (!isFlutterProject()) {
      throw Exception('Run `use` command on the root of a Flutter project');
    }

    if (argResults.rest.isEmpty) {
      final instruction = yellow.wrap('fvm use <version>');
      throw Exception('Please provide a version. $instruction');
    }
    final version = argResults.rest[0];

    final isInstalled = await isSdkInstalled(version);

    if (!isInstalled) {
      print('Flutter $version is not installed.');
      var inputConfirm = await readInput('Would you like to install it? Y/n: ');

      // Install if input is confirmed
      if (!inputConfirm.contains('n')) {
        final installProgress = logger.progress('Installing $version');
        await installFlutterVersion(version);
        finishProgress(installProgress);
      } else {
        // If do not install exist
        exit(0);
      }
    }

    updateProjectConfig(version);

    print(green.wrap('$version is active'));
  }
}
