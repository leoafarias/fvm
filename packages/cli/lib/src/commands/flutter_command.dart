import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_tools.dart';
import 'package:fvm/src/utils/logger.dart';

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
    final project = await FlutterProjectRepo.findAncestor();

    if (project != null && project.pinnedVersion != null) {
      logger.trace('FVM: Running version ${project.pinnedVersion}');

      await runFlutterCmd(project.pinnedVersion, argResults.arguments);
    } else {
      logger.trace(
        'FVM: Running using Flutter version configured in path.',
      );
      // Running null will default to flutter version on path
      await runFlutterCmd(null, argResults.arguments);
    }
  }
}
