import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:io/io.dart';

import '../exceptions.dart';
import 'commands/config_command.dart';
import 'commands/dart_command.dart';
import 'commands/env_command.dart';
import 'commands/flutter_command.dart';
import 'commands/git_cache_command.dart';
import 'commands/global_command.dart';
import 'commands/install_command.dart';
import 'commands/list_command.dart';
import 'commands/releases_command.dart';
import 'commands/remove_command.dart';
import 'commands/spawn_command.dart';
import 'commands/use_command.dart';
import 'commands/which_command.dart';
import 'utils/logger.dart';
import 'utils/logger.dart' show logger;
import 'utils/pubdev.dart';
import 'version.dart';

/// Command Runner for FVM
class FvmCommandRunner extends CommandRunner<int> {
  /// Constructor
  FvmCommandRunner()
      : super('fvm',
            '''Flutter Version Management: A cli to manage Flutter SDK versions.''') {
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
        help: 'current version',
        negatable: false,
      );
    addCommand(InstallCommand());
    addCommand(UseCommand());
    addCommand(ListCommand());
    addCommand(RemoveCommand());
    addCommand(ReleasesCommand());
    addCommand(FlutterCommand());
    addCommand(DartCommand());
    addCommand(GlobalCommand());
    addCommand(WhichCommand());
    addCommand(SpawnCommand());
    addCommand(ConfigCommand());
    addCommand(EnvCommand());
    addCommand(GitCacheCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      ConsoleController.isCli = true;
      final _argResults = parse(args);

      final exitCode = await runCommand(_argResults) ?? ExitCode.success.code;

      // Command might be null
      final cmd = _argResults?.command?.name;

      // Check if its running the latest version of FVM
      if (cmd == 'use' || cmd == 'install' || cmd == 'remove') {
        await checkIfLatestVersion();
      }
      return exitCode;
    } on FvmUsageException catch (e) {
      FvmLogger.spacer();
      FvmLogger.error(e.message);
      FvmLogger.spacer();
      FvmLogger.info(usage);
      FvmLogger.spacer();
      return ExitCode.usage.code;
    } on FvmInternalError catch (e, stackTrace) {
      FvmLogger.spacer();
      FvmLogger.error(e.message);
      logger.trace('$stackTrace');
      FvmLogger.spacer();
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      FvmLogger.spacer();
      FvmLogger.error(e.message);
      FvmLogger.spacer();
      FvmLogger.info(usage);
      FvmLogger.spacer();
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      FvmLogger.info(packageVersion);
      return ExitCode.success.code;
    }

    return super.runCommand(topLevelResults);
  }
}
