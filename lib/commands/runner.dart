import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:fvm/utils/logger.dart';

/// Builds FVM Runner
CommandRunner buildRunner() {
  final runner = CommandRunner('fvm',
      'Flutter Version Management: A cli to manage Flutter SDK versions.');

  runner.argParser.addFlag('verbose',
      help: 'Print verbose output.', negatable: false, callback: (verbose) {
    if (verbose) {
      logger = Logger.verbose();
    } else {
      logger = Logger.standard();
    }
  });

  return runner;
}
