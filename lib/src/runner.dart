import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:fvm/exceptions.dart';

import 'package:fvm/src/commands/config_command.dart';
import 'package:fvm/src/utils/logger.dart';

import 'package:fvm/src/commands/flutter_command.dart';
import 'package:fvm/src/commands/dart_command.dart';
import 'package:fvm/src/commands/install_command.dart';
import 'package:fvm/src/commands/list_command.dart';
import 'package:fvm/src/commands/releases_command.dart';
import 'package:fvm/src/commands/remove_command.dart';

import 'package:fvm/src/commands/use_command.dart';

import 'package:fvm/src/utils/logger.dart' show logger;
import 'package:fvm/src/version.dart';

import 'package:io/io.dart';

class FvmCommandRunner extends CommandRunner<int> {
  FvmCommandRunner()
      : super('fvm',
            'Flutter Version Management: A cli to manage Flutter SDK versions.') {
    argParser
      ..addFlag(
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
      )
      ..addFlag(
        'version',
        help: 'Print the current version',
        negatable: false,
      );
    addCommand(InstallCommand());
    addCommand(ListCommand());
    addCommand(FlutterCommand());
    addCommand(DartCommand());
    addCommand(RemoveCommand());
    addCommand(UseCommand());
    addCommand(ConfigCommand());
    addCommand(ReleasesCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      ConsoleController.isCli = true;
      final _argResults = parse(args);
      return await runCommand(_argResults) ?? ExitCode.success.code;
    } on UsageException catch (e) {
      FvmLogger.warning(e.message);
      FvmLogger.info('');
      return ExitCode.usage.code;
    } on InternalError catch (e, stackTrace) {
      FvmLogger.error(e.message);
      FvmLogger.error('$stackTrace');
      FvmLogger.info('');
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      print(packageVersion);
      return ExitCode.success.code;
    }

    return super.runCommand(topLevelResults);
  }
}
