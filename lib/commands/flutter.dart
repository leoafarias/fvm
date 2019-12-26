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
      ..addOption('build-number',
          help: '''An identifier used as an internal version number.
          Each build must have a unique identifier to differentiate it from previous builds.
          It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.
          On Android it is used as 'versionCode'.
          On Xcode builds it is used as 'CFBundleVersion' ''')
      ..addFlag('version', negatable: false,
          help: '''Reports the version of this tool, on the local version.''')
      ..addFlag('suppress-analytics',
          help: '''Suppress analytics reporting when this command runs.''')
      ..addFlag('bug-report', negatable: false,
          help:
              '''Captures a bug report file to submit to the Flutter team. Contains local paths, device identifiers, and log snippets.''')
      ..addFlag('debug', help: '''Build a debug version of your app.''')
      ..addFlag('release', negatable: false,
          help: '''Build a release version of your app (default mode).''')
      ..addFlag('codesign',
          help:
              '''Codesign the application bundle (only available on device builds).  (defaults to on)''');
  }

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
