import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/flutter/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:args/args.dart';
import 'package:fvm/utils/print.dart';
import 'package:fvm/utils/project_config.dart';
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
    var flutterExec = getFlutterSdkExec();
    if (flutterExec == '') {
      final globalFlutter = await which('flutter');
      if (globalFlutter == '') {
        throw Exception('FVM: Flutter not found in path');
      }
      flutterExec = globalFlutter;
      PrettyPrint.info('FVM: Global Flutter\nPath: $flutterExec\n');
    } else {
      PrettyPrint.info(
          'FVM: Local Flutter ${getConfigFlutterVersion()}\nPath:($flutterExec)\n');
    }

    await flutterCmd(flutterExec, argResults.arguments,
        workingDirectory: kWorkingDirectory.path);
  }
}
