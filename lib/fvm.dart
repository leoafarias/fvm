import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:fvm/commands/channel.dart';
import 'package:fvm/commands/list_versions.dart';
import 'package:fvm/utils/logger.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:fvm/utils/logger.dart' show logger;

/// Runs FVM
Future<void> fvmRunner(List<String> args) async {
  final runner = CommandRunner('fvm',
      'Flutter Version Management: A cli to manage Flutter SDK versions.');

  runner.argParser.addFlag('verbose',
      help: 'Print verbose output.', negatable: false, callback: (verbose) {
    if (verbose) {
      logger = Logger.verbose();
    } else {
      logger = Logger.standard();
    }
    ;
  });

  runner..addCommand(ChannelCommand());
  runner..addCommand(ListVersionsCommand());

  return await runner.run(args).catchError((exc, st) {
    if (exc is String) {
      logger.stdout(exc);
    } else {
      logger.stderr("Oops, something went wrong: ${exc?.message}");
      if (args.contains('--verbose')) {
        logger.stderr(st);
      }
    }

    exitCode = 1;
  }).whenComplete(() {
    logger.stdout('');
  });
}
