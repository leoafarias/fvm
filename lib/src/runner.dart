import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:stack_trace/stack_trace.dart';

import 'commands/api_command.dart';
import 'commands/config_command.dart';
import 'commands/dart_command.dart';
import 'commands/destroy_command.dart';
import 'commands/doctor_command.dart';
import 'commands/exec_command.dart';
import 'commands/flavor_command.dart';
import 'commands/flutter_command.dart';
import 'commands/global_command.dart';
import 'commands/install_command.dart';
import 'commands/list_command.dart';
import 'commands/releases_command.dart';
import 'commands/remove_command.dart';
import 'commands/spawn_command.dart';
import 'commands/use_command.dart';
import 'services/config_repository.dart';
import 'utils/constants.dart';
import 'utils/context.dart';
import 'utils/deprecation_util.dart';
import 'utils/exceptions.dart';
import 'version.dart';

/// Command Runner for FVM
class FvmCommandRunner extends CompletionCommandRunner<int> {
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
        help: 'Print the current version.',
        negatable: false,
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
    addCommand(DestroyCommand());
    addCommand(APICommand());
    addCommand(GlobalCommand());
    addCommand(FlavorCommand());
  }

  /// Checks if the current version (set by the build runner on the
  /// version.dart file) is the most recent one. If not, show a prompt to the
  /// user.
  Future<Function()?> _checkForUpdates() async {
    try {
      final lastUpdateCheck = ctx.lastUpdateCheck ?? DateTime.now();
      if (ctx.updateCheckDisabled) return null;
      final oneDay = lastUpdateCheck.add(const Duration(days: 1));

      if (DateTime.now().isBefore(oneDay)) {
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

        ctx.loggerService
          ..spacer
          ..info(
            '$updateAvailableLabel $currentVersionLabel \u2192 $latestVersionLabel',
          )
          ..spacer;
      };
    } catch (_) {
      return () {
        ctx.loggerService.detail("Failed to check for updates.");
      };
    }
  }

  @override
  void printUsage() => ctx.loggerService.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      deprecationWorkflow();

      final argResults = parse(args);

      if (argResults['verbose'] == true) {
        ctx.loggerService.level = Level.verbose;
      }

      final exitCode = await runCommand(argResults) ?? ExitCode.success.code;

      return exitCode;
    } on AppDetailedException catch (err, stackTrace) {
      ctx.loggerService
        ..fail(err.message)
        ..spacer
        ..err(err.info);

      _printTrace(stackTrace);

      return ExitCode.unavailable.code;
    } on FileSystemException catch (err, stackTrace) {
      if (checkIfNeedsPrivilegePermission(err)) {
        ctx.loggerService
          ..spacer
          ..fail('Requires administrator privileges to run this command.')
          ..spacer;

        ctx.loggerService.notice(
          "You don't have the required privileges to run this command.\n"
          "Try running with sudo or administrator privileges.\n"
          "If you are on Windows, you can turn on developer mode: https://bit.ly/3vxRr2M",
        );

        return ExitCode.noPerm.code;
      }

      ctx.loggerService
        ..err(err.message)
        ..spacer
        ..err('Path: ${err.path}');

      _printTrace(stackTrace);

      return ExitCode.ioError.code;
    } on AppException catch (err) {
      ctx.loggerService.fail(err.message);

      return ExitCode.data.code;
    } on ProcessException catch (e) {
      ctx.loggerService
        ..spacer
        ..err(e.toString())
        ..spacer;

      return e.errorCode;
    } on UsageException catch (err) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      ctx.loggerService
        ..err(err.message)
        ..spacer
        ..info(err.usage);

      return ExitCode.usage.code;
    } on Exception catch (err, stackTrace) {
      ctx.loggerService
        ..spacer
        ..err(err.toString());

      _printTrace(stackTrace);

      return ExitCode.unavailable.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Verbose logs
    ctx.loggerService
      ..detail('')
      ..detail('Argument information:');

    if (topLevelResults.command?.name == 'completion') {
      super.runCommand(topLevelResults);

      return ExitCode.success.code;
    }

    final hasTopLevelOption =
        topLevelResults.options.any((e) => topLevelResults.wasParsed(e));

    if (hasTopLevelOption) {
      ctx.loggerService.detail('  Top level options:');
      for (final option in topLevelResults.options) {
        if (topLevelResults.wasParsed(option)) {
          ctx.loggerService.detail('  - $option: ${topLevelResults[option]}');
        }
      }
      ctx.loggerService.detail('');
    }

    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      ctx.loggerService.detail('Command: ${commandResult.name}');

      // Check if any command option was parsed
      final hasCommandOption =
          commandResult.options.any((e) => commandResult.wasParsed(e));

      if (hasCommandOption) {
        ctx.loggerService.detail('  Command options:');
        for (final option in commandResult.options) {
          if (commandResult.wasParsed(option)) {
            ctx.loggerService.detail('    - $option: ${commandResult[option]}');
          }
        }
      }

      ctx.loggerService.detail('');
    }

    final checkingForUpdate = _checkForUpdates();

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      ctx.loggerService.info(packageVersion);
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
  ctx.loggerService
    ..detail('')
    ..detail(trace);

  if (ctx.loggerService.level != Level.verbose) {
    ctx.loggerService
      ..spacer
      ..info(
        'Please run command with  --verbose if you want more information',
      );
  }
}
