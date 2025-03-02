import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:pub_updater/pub_updater.dart';

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
import 'models/log_level_model.dart';
import 'services/config_repository.dart';
import 'utils/constants.dart';
import 'utils/context.dart';
import 'utils/exceptions.dart';
import 'version.dart';

/// Command Runner for FVM
class FvmCommandRunner extends CompletionCommandRunner<int> {
  final FVMContext context;
  final PubUpdater _pubUpdater;

  /// Constructor
  FvmCommandRunner(this.context, {PubUpdater? pubUpdater})
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
    addCommand(InstallCommand(context));
    addCommand(UseCommand(context));
    addCommand(ListCommand(context));
    addCommand(RemoveCommand(context));
    addCommand(ReleasesCommand(context));
    addCommand(FlutterCommand(context));
    addCommand(DartCommand(context));
    addCommand(DoctorCommand(context));
    addCommand(SpawnCommand(context));
    addCommand(ConfigCommand(context));
    addCommand(ExecCommand(context));
    addCommand(DestroyCommand(context));
    addCommand(APICommand(context));
    addCommand(GlobalCommand(context));
    addCommand(FlavorCommand(context));
  }

  /// Checks if the current version (set by the build runner on the
  /// version.dart file) is the most recent one. If not, show a prompt to the
  /// user.
  Future<Function()?> _checkForUpdates() async {
    try {
      final lastUpdateCheck = context.lastUpdateCheck ?? DateTime.now();
      if (context.updateCheckDisabled) return null;
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

        context.logger
          ..lineBreak()
          ..info(
            '$updateAvailableLabel $currentVersionLabel \u2192 $latestVersionLabel',
          )
          ..lineBreak();
      };
    } catch (_) {
      return () {
        context.logger.detail("Failed to check for updates.");
      };
    }
  }

  @override
  void printUsage() => context.logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);

      if (argResults['verbose'] == true) {
        context.logger.level = Level.verbose;
      }

      final exitCode = await runCommand(argResults) ?? ExitCode.success.code;

      return exitCode;
    } on ApiCommandException catch (err, stackTrace) {
      context.logger
        ..fail(err.message)
        ..lineBreak()
        ..err(err.error.toString());
      context.logger.logTrace(stackTrace);

      return ExitCode.unavailable.code;
    } on AppDetailedException catch (err, stackTrace) {
      context.logger
        ..fail(err.message)
        ..lineBreak()
        ..err(err.info);
      context.logger.logTrace(stackTrace);

      return ExitCode.unavailable.code;
    } on FileSystemException catch (err, stackTrace) {
      if (checkIfNeedsPrivilegePermission(err)) {
        context.logger
          ..lineBreak()
          ..fail('Requires administrator privileges to run this command.')
          ..lineBreak();

        context.logger.notice(
          "You don't have the required privileges to run this command.\n"
          "Try running with sudo or administrator privileges.\n"
          "If you are on Windows, you can turn on developer mode: https://bit.ly/3vxRr2M",
        );

        return ExitCode.noPerm.code;
      }

      context.logger
        ..err(err.message)
        ..lineBreak()
        ..err('Path: ${err.path}');
      context.logger.logTrace(stackTrace);

      return ExitCode.ioError.code;
    } on AppException catch (err) {
      context.logger.fail(err.message);

      return ExitCode.data.code;
    } on ProcessException catch (e) {
      context.logger
        ..lineBreak()
        ..err(e.toString())
        ..lineBreak();

      return e.errorCode;
    } on UsageException catch (err) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      context.logger
        ..err(err.message)
        ..lineBreak()
        ..info(err.usage);

      return ExitCode.usage.code;
    } on Exception catch (err, stackTrace) {
      context.logger
        ..lineBreak()
        ..err(err.toString());

      context.logger.logTrace(stackTrace);

      return ExitCode.unavailable.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Verbose logs
    context.logger
      ..detail('')
      ..detail('Argument information:');

    if (topLevelResults.command?.name == 'completion') {
      super.runCommand(topLevelResults);

      return ExitCode.success.code;
    }

    if (topLevelResults.command?.name == 'api') {
      await super.runCommand(topLevelResults);

      return ExitCode.success.code;
    }

    final hasTopLevelOption =
        topLevelResults.options.any((e) => topLevelResults.wasParsed(e));

    if (hasTopLevelOption) {
      context.logger.detail('  Top level options:');
      for (final option in topLevelResults.options) {
        if (topLevelResults.wasParsed(option)) {
          context.logger.detail('  - $option: ${topLevelResults[option]}');
        }
      }
      context.logger.detail('');
    }

    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      context.logger.detail('Command: ${commandResult.name}');

      // Check if any command option was parsed
      final hasCommandOption =
          commandResult.options.any((e) => commandResult.wasParsed(e));

      if (hasCommandOption) {
        context.logger.detail('  Command options:');
        for (final option in commandResult.options) {
          if (commandResult.wasParsed(option)) {
            context.logger.detail('    - $option: ${commandResult[option]}');
          }
        }
      }

      context.logger.detail('');
    }

    final checkingForUpdate = _checkForUpdates();

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      context.logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    final logOutput = await checkingForUpdate;
    logOutput?.call();

    return exitCode;
  }
}
