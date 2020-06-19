import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/print.dart';
import 'package:io/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/utils/flutter_tools.dart';

/// List installed SDK Versions
class ListCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Version';

  /// Constructor
  ListCommand();

  @override
  void run() {
    final choices = flutterListInstalledSdks();

    if (choices.isEmpty) {
      Print.info(
          'No SDKs have been installed yet. Flutter SDKs installed outside of fvm will not be displayed.');
      exit(0);
    }

    // Print where versions are stored
    print('Versions path:  ${yellow.wrap(kVersionsDir.path)}');

    void printVersions(String version) {
      if (isCurrentVersion(version)) {
        version = '$version (current)';
      }
      Print.info(version);
    }

    for (var choice in choices) {
      printVersions(choice);
    }
  }
}
