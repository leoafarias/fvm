import 'dart:io';

import 'package:console/console.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';

import 'package:fvm/src/local_versions/local_version.repo.dart';
import 'package:fvm/src/flutter_project/flutter_project.model.dart';
import 'package:fvm/src/utils/pretty_print.dart';
import 'package:io/ansi.dart';
import 'package:args/command_runner.dart';

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
  void run() async {
    final choices = await LocalVersionRepo().getAll();

    if (choices.isEmpty) {
      PrettyPrint.info(
        '''
        No SDKs have been installed yet. Flutter 
        SDKs installed outside of fvm will not be displayed.
        ''',
      );
      exit(0);
    }

    // Print where versions are stored
    print('Versions path:  ${yellow.wrap(kVersionsDir.path)}');

    // Get current project
    final project = await FlutterProjectRepo().findOne();

    for (var choice in choices) {
      printVersions(choice.name, project);
    }
  }
}

void printVersions(String version, FlutterProject project) {
  var printVersion = version;
  if (project.pinnedVersion == version) {
    printVersion = '$printVersion ${Icon.HEAVY_CHECKMARK}';
  }
  if (isGlobalVersion(version)) {
    printVersion = '$printVersion (global)';
  }
  PrettyPrint.info(printVersion);
}
