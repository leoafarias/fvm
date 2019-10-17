import 'dart:io';

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

  /// Constructor
  FlutterCommand() {
    argParser
      ..addOption('device-id',
          abbr: 'd', help: '''Target device id or name (prefixes allowed).''')
      ..addFlag('version',
          help: '''Reports the version of this tool, on the local version.''')
      ..addFlag('suppress-analytics',
          help: '''Suppress analytics reporting when this command runs.''')
      ..addFlag('bug-report',
          help:
              '''Captures a bug report file to submit to the Flutter team. Contains local paths, device identifiers, and log snippets.''');
  }

  Future<void> run() async {
    final flutterProjectLink = projectFlutterLink();

    if (flutterProjectLink == null) {
      throw Exception('No FVM config found. Create with <use> command');
    }

    if (!await flutterProjectLink.exists()) {
      throw Exception('No FVM config found. Create with <use> command');
    }

    final targetLink = File(await flutterProjectLink.target());

    if (!await flutterProjectLink.exists()) {
      throw Exception('Issue found with FVM config. Create with <use> command');
    }
    await processRunner(targetLink.path, argResults.arguments,
        workingDirectory: kWorkingDirectory.path);
  }
}
