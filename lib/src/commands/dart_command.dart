import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_tools.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/install_version.workflow.dart';

/// Proxies Dart Commands
class DartCommand extends Command<int> {
  // The [name] and [description] properties must be defined by every
  // subclass.

  @override
  final name = 'dart';
  @override
  final description = 'Proxies Dart Commands';
  @override
  final argParser = ArgParser.allowAnything();

  @override
  Future<int> run() async {
    final project = await FlutterProjectRepo.findAncestor();

    if (project != null && project.pinnedVersion != null) {
      logger.trace('FVM: Running version ${project.pinnedVersion}');
      // Will install version if not already instaled
      await installWorkflow(project.pinnedVersion);
      // Runs flutter command with pinned version
      return await runDartCmd(project.pinnedVersion, argResults.arguments);
    } else {
      logger.trace(
        'FVM: Running using Flutter version configured in path.',
      );
      // Running null will default to flutter version on path
      return await runDartCmd(null, argResults.arguments);
    }
  }
}
