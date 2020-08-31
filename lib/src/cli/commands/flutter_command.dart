import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_project/flutter_project.model.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/flutter_tools/flutter_tools.dart';

import 'package:args/args.dart';
import 'package:fvm/src/utils/helpers.dart';

/// Proxies Flutter Commands
class FlutterCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.

  @override
  final name = 'flutter';
  @override
  final description = 'Proxies Flutter Commands';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  FlutterCommand();

  @override
  Future<void> run() async {
    final project = FlutterProject.find();

    final flutterExec = getFlutterSdkExec(project.pinnedVersion);
    // Make sure that version is installed
    await checkAndInstallVersion(project.pinnedVersion);

    await runFlutter(
      flutterExec,
      argResults.arguments,
      workingDirectory: kWorkingDirectory.path,
    );
  }
}
