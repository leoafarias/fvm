import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/src/commands/git_cache_command.dart';
import 'package:fvm/src/commands/update_command.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

import '../exceptions.dart';
import 'commands/config_command.dart';
import 'commands/dart_command.dart';
import 'commands/destroy_command.dart';
import 'commands/doctor_command.dart';
import 'commands/exec_command.dart';
import 'commands/flavor_command.dart';
import 'commands/flutter_command.dart';
import 'commands/install_command.dart';
import 'commands/list_command.dart';
import 'commands/releases_command.dart';
import 'commands/remove_command.dart';
import 'commands/spawn_command.dart';
import 'commands/use_command.dart';
import 'version.dart';

/// Command Runner for FVM
class FvmCommandRunner extends CommandRunner<int> {
  /// Constructor
  FvmCommandRunner({
    PubUpdater? pubUpdater,
  })  : _pubUpdater = pubUpdater ?? PubUpdater(),
        super(
          kPackageName,
          kDescription,
        ) {
    argParser
      ..addFlag(
        'verbose',
        help: 'Print verbose output.',
      )
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print the current version.',
      );
    addCommand(InstallCommand());
    addCommand(UseCommand());
    addCommand(ListCommand());
    addCommand(RemoveCommand());
    addCommand(ReleasesCommand());
    addCommand(FlutterCommand());
    addCommand(DartCommand());
    addCommand(DoctorCommand());
    addCommand(SpawnCommand());
    addCommand(ConfigCommand());
    addCommand(FlavorCommand());
    addCommand(DestroyCommand());
    addCommand(ExecCommand());
    addCommand(GitCacheCommand());
    addCommand(UpdateCommand());
  }

  final PubUpdater _pubUpdater;

  @override
  void printUsage() => logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);
      if (argResults['verbose'] == true) {
        logger.level = Level.verbose;
      }

      final exitCode = await runCommand(argResults) ?? ExitCode.success.code;

      return exitCode;
    } on FormatException catch (e, stackTrace) {
      // On format errors, show the commands error message, root usage and
      // exit with an error code
      logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on FvmError catch (e, stackTrace) {
      logger
        ..err(e.toString())
        ..spacer
        ..detail('$stackTrace\n');

      if (logger.level != Level.verbose) {
        logger.info(
          'Please run command with  --verbose if you want more information',
        );
      }

      return ExitCode.unavailable.code;
    } on FvmProcessRunnerException catch (e) {
      logger
        ..err(e.message)
        ..spacer
        ..detail(e.result.stderr.toString());

      if (logger.level != Level.verbose) {
        logger.info(
          'Please run command with  --verbose if you want more information',
        );
      }

      return e.result.exitCode;
    } on UsageException catch (e) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);

      return ExitCode.usage.code;
    } on Exception catch (e) {
      logger.err(e.toString());
      return ExitCode.unavailable.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Verbose logs
    logger
      ..spacer
      ..detail('Argument information:')
      ..detail('Top level options:');
    for (final option in topLevelResults.options) {
      if (topLevelResults.wasParsed(option)) {
        logger.detail('  - $option: ${topLevelResults[option]}');
      }
    }
    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      logger
        ..detail('  Command: ${commandResult.name}')
        ..detail('    Command options:');
      for (final option in commandResult.options) {
        if (commandResult.wasParsed(option)) {
          logger.detail('    - $option: ${commandResult[option]}');
        }
      }
    }

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    // Command might be null
    final cmd = topLevelResults.command?.name;

    // Check if its running the latest version of FVM
    if (cmd == 'use' || cmd == 'install' || cmd == 'remove') {
      // Check if there is an update for FVM
      await _checkForUpdates();
    }

    return exitCode;
  }

  /// Checks if the current version (set by the build runner on the
  /// version.dart file) is the most recent one. If not, show a prompt to the
  /// user.
  Future<void> _checkForUpdates() async {
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(kDescription);
      final isUpToDate = packageVersion == latestVersion;
      if (!isUpToDate) {
        logger
          ..info('')
          ..info(
            '''
${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}
Run ${lightCyan.wrap('$executableName update')} to update''',
          );
      }
    } catch (_) {}
  }
}
