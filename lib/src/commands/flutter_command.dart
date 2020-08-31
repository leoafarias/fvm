import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';

import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/flutter_tools/flutter_tools.dart';

import 'package:args/args.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/pretty_print.dart';
import 'package:process_run/which.dart';

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
    final project = await FlutterProjectRepo().findOne();

    String flutterExec;

    if (project != null) {
      flutterExec = getFlutterSdkExec(project.pinnedVersion);
      // Make sure that version is installed
      await checkAndInstallVersion(project.pinnedVersion);
      PrettyPrint.info('FVM: Running version ${project.pinnedVersion}');
    } else {
      // Use global configured version as fallback
      flutterExec = await which('flutter');
      if (flutterExec == '') {
        throw Exception('FVM: Flutter not found in path');
      }
      PrettyPrint.info(
        'FVM: Running using Flutter version configured in path.',
      );
    }

    await runFlutter(
      flutterExec,
      argResults.arguments,
      workingDirectory: kWorkingDirectory.path,
    );
  }
}
