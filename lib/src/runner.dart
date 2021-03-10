import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import 'package:fvm/src/commands/config_command.dart';
import 'package:fvm/src/utils/logger.dart';

import 'package:fvm/src/commands/flutter_command.dart';
import 'package:fvm/src/commands/dart_command.dart';
import 'package:fvm/src/commands/install_command.dart';
import 'package:fvm/src/commands/list_command.dart';
import 'package:fvm/src/commands/releases_command.dart';
import 'package:fvm/src/commands/remove_command.dart';

import 'package:fvm/src/commands/use_command.dart';
import 'package:fvm/src/commands/version_command.dart';

import 'package:fvm/src/utils/logger.dart' show logger;
import 'package:io/ansi.dart';

/// Runs FVM
Future<void> fvmRunner(List<String> args) async {
  ConsoleController.isCli = true;
  final runner = buildRunner();

  runner..addCommand(InstallCommand());
  runner..addCommand(ListCommand());
  runner..addCommand(DartCommand());
  runner..addCommand(FlutterCommand());
  runner..addCommand(RemoveCommand());
  runner..addCommand(UseCommand());
  runner..addCommand(VersionCommand());
  runner..addCommand(ConfigCommand());
  runner..addCommand(ReleasesCommand());

  try {
    await runner.run(args);
  } catch (exc, st) {
    if (exc is String) {
      FvmLogger.warning(exc);
    } else {
      FvmLogger.warning('${yellow.wrap(exc.toString())}');
      if (args.contains('--verbose')) {
        FvmLogger.error(st.toString());
        rethrow;
      }
    }
    exitCode = 1;
  }
}

/// Builds FVM Runner
CommandRunner buildRunner() {
  final runner = CommandRunner('fvm',
      'Flutter Version Management: A cli to manage Flutter SDK versions.');

  runner.argParser.addFlag(
    'verbose',
    help: 'Print verbose output.',
    negatable: false,
    callback: (verbose) {
      if (verbose) {
        logger = Logger.verbose();
      } else {
        logger = Logger.standard();
      }
    },
  );

  return runner;
}
