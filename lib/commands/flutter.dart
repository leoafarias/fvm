import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';

/// Proxies Flutter Commands
class FlutterCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "flutter";
  final description = "Proxies Flutter Commands";
  final argParser = ArgParser.allowAnything();

  /// Constructor
  FlutterCommand();

  Future<void> run() async {
    final flutterProjectLink = await projectFlutterLink();

    if (flutterProjectLink == null || !await flutterProjectLink.exists()) {
      throw Exception('No FVM config found. Create with <use> command');
    }

    try {
      final targetLink = File(await flutterProjectLink.target());

      await processRunner(targetLink.path, argResults.arguments,
          workingDirectory: kWorkingDirectory.path);
    } on Exception {
      rethrow;
    }
  }
}
