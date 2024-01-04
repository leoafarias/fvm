import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/src/commands/global_command.dart';
import 'package:fvm/src/commands/update_command.dart';
import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/deprecation_util.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:stack_trace/stack_trace.dart';

import '../exceptions.dart';
import 'commands/config_command.dart';
import 'commands/dart_command.dart';
import 'commands/doctor_command.dart';
import 'commands/exec_command.dart';
import 'commands/flutter_command.dart';
import 'commands/install_command.dart';
import 'commands/list_command.dart';
import 'commands/releases_command.dart';
import 'commands/remove_command.dart';
import 'commands/spawn_command.dart';
import 'commands/use_command.dart';
import 'version.g.dart';

/// Command Runner for FVM
class FvmCommandRunner extends CommandRunner<int> {
  final PubUpdater _pubUpdater;

  /// Constructor
  FvmCommandRunner({PubUpdater? pubUpdater})
      : _pubUpdater = pubUpdater ?? PubUpdater(),
        super(kPackageName, kDescription) {
    argParser
      ..addFlag('verbose', help: 'Print verbose output.', negatable: false)
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
    addCommand(ExecCommand());
    addCommand(UpdateCommand());
    addCommand(GlobalCommand());
  }

  /// Checks if the current version (set by the build runner on the
  /// version.dart file) is the most recent one. If not, show a prompt to the
  /// user.
  Future<Function()?> _checkForUpdates() async {
    try {
      if (ctx.updateCheckDisabled) return null;
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      if (ctx.lastUpdateCheck?.isBefore(oneDayAgo) ?? false) {
        return null;
      }

      ConfigRepository.update(lastUpdateCheck: DateTime.now());

      final isUpToDate = await _pubUpdater.isUpToDate(
        packageName: kPackageName,
        currentVersion: packageVersion,
      );

      if (isUpToDate) return null;

      final latestVersion = await _pubUpdater.getLatestVersion(kPackageName);

      return () {
        final updateAvailableLabel = lightYellow.wrap('Update available!');
        final currentVersionLabel = lightCyan.wrap(packageVersion);
        final latestVersionLabel = lightCyan.wrap(latestVersion);
        final updateCommandLabel = lightCyan.wrap('$executableName update');

        logger
          ..spacer
          ..info(
            '$updateAvailableLabel $currentVersionLabel \u2192 $latestVersionLabel',
          )
          ..info('Run $updateCommandLabel to update')
          ..spacer;
      };
    } catch (_) {
      return () {
        logger.detail("Failed to check for updates.");
      };
    }
  }

  @override
  void printUsage() => logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      deprecationWorkflow();

      final argResults = parse(args);

      if (argResults['verbose'] == true) {
        logger.level = Level.verbose;
      }
      // Add space before any output
      logger.spacer;

      final exitCode = await runCommand(argResults) ?? ExitCode.success.code;

      return exitCode;
    } on AppDetailedException catch (err, stackTrace) {
      logger
        ..fail(err.message)
        ..spacer
        ..err(err.info);

      _printTrace(stackTrace);

      return ExitCode.unavailable.code;
    } on FileSystemException catch (err, stackTrace) {
      if (checkIfNeedsPrivilegePermission(err)) {
        logger
          ..spacer
          ..fail('Requires administrator priviledges to run this command.')
          ..spacer;

        logger.notice(
          "You don't have the required priviledges to run this command.\n"
          "Try running with sudo or administrator priviledges.\n"
          "If you are on Windows, you can turn on developer mode: https://bit.ly/3vxRr2M",
        );
        return ExitCode.noPerm.code;
      }

      logger
        ..err(err.message)
        ..spacer
        ..err('Path: ${err.path}');

      _printTrace(stackTrace);

      return ExitCode.ioError.code;
    } on AppException catch (err) {
      logger.fail(err.message);

      return ExitCode.data.code;
    } on ProcessException catch (e) {
      logger
        ..spacer
        ..err(e.toString())
        ..spacer;

      return e.errorCode;
    } on UsageException catch (err) {
      // On usagerr errors, show the commands usage message and
      // exit with an error code
      logger
        ..err(err.message)
        ..spacer
        ..info(err.usage);

      return ExitCode.usage.code;
    } on Exception catch (err, stackTrace) {
      logger
        ..spacer
        ..err(err.toString());

      _printTrace(stackTrace);
      return ExitCode.unavailable.code;
    } finally {
      // Add spacer after the last line always
      logger.spacer;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Verbose logs
    logger
      ..detail('')
      ..detail('Argument information:');

    final hasTopLevelOption = topLevelResults.options
        .where((e) => topLevelResults.wasParsed(e))
        .isNotEmpty;

    if (hasTopLevelOption) {
      logger.detail('  Top level options:');
      for (final option in topLevelResults.options) {
        if (topLevelResults.wasParsed(option)) {
          logger.detail('  - $option: ${topLevelResults[option]}');
        }
      }
      logger.detail('');
    }

    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      logger.detail('Command: ${commandResult.name}');

      // Check if any command option was parsed
      final hasCommandOption = commandResult.options
          .where((e) => commandResult.wasParsed(e))
          .isNotEmpty;

      if (hasCommandOption) {
        logger.detail('  Command options:');
        for (final option in commandResult.options) {
          if (commandResult.wasParsed(option)) {
            logger.detail('    - $option: ${commandResult[option]}');
          }
        }
      }

      logger.detail('');
    }

    final checkingForUpdate = _checkForUpdates();

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    final logOutput = await checkingForUpdate;
    logOutput?.call();

    return exitCode;
  }
}

void _printTrace(StackTrace stackTrace) {
  final trace = Trace.from(stackTrace).toString();
  logger
    ..detail('')
    ..detail(trace);

  if (logger.level != Level.verbose) {
    logger
      ..spacer
      ..info(
        'Please run command with  --verbose if you want more information',
      );
  }
}
