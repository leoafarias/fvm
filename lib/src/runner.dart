import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:pub_semver/pub_semver.dart';

import 'commands/api_command.dart';
import 'commands/config_command.dart';
import 'commands/dart_command.dart';
import 'commands/destroy_command.dart';
import 'commands/doctor_command.dart';
import 'commands/exec_command.dart';
import 'commands/flavor_command.dart';
import 'commands/flutter_command.dart';
import 'commands/fork_command.dart';
import 'commands/global_command.dart';
import 'commands/install_command.dart';
import 'commands/integration_test_command.dart';
import 'commands/list_command.dart';
import 'commands/releases_command.dart';
import 'commands/remove_command.dart';
import 'commands/spawn_command.dart';
import 'commands/use_command.dart';
import 'models/config_model.dart';
import 'models/log_level_model.dart';
import 'services/fvm_release_service.dart';
import 'services/logger_service.dart';
import 'utils/constants.dart';
import 'utils/context.dart';
import 'utils/exceptions.dart';
import 'version.dart';

/// Command Runner for FVM
class FvmCommandRunner extends CompletionCommandRunner<int> {
  final FvmContext context;
  final FvmReleaseService _releaseService;
  static const _updateCheckInterval = Duration(days: 1);

  /// Constructor
  FvmCommandRunner(this.context, {FvmReleaseService? releaseService})
      : _releaseService = releaseService ?? context.get<FvmReleaseService>(),
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
    addCommand(ForkCommand(context));
    addCommand(DoctorCommand(context));
    addCommand(SpawnCommand(context));
    addCommand(ConfigCommand(context));
    addCommand(ExecCommand(context));
    addCommand(DestroyCommand(context));
    addCommand(APICommand(context));
    addCommand(GlobalCommand(context));
    addCommand(FlavorCommand(context));
    addCommand(IntegrationTestCommand(context));
  }

  /// Returns a notice when a newer stable FVM release is available.
  Future<void Function()?> _checkForUpdates() async {
    try {
      if (context.updateCheckDisabled) return null;

      final now = DateTime.now();
      final lastUpdateCheck = context.lastUpdateCheck;
      if (lastUpdateCheck != null &&
          now.isBefore(lastUpdateCheck.add(_updateCheckInterval))) {
        return null;
      }

      LocalAppConfig.read(path: context.appConfigPath, requireValid: true)
        ..lastUpdateCheck = now
        ..save(path: context.appConfigPath);

      final latestRelease = await _releaseService.getLatestStableRelease();
      final currentVersion = Version.parse(packageVersion);
      if (latestRelease.version.compareTo(currentVersion) <= 0) return null;

      return () => _showUpdateNotice(latestRelease, currentVersion);
    } catch (_) {
      return () => logger.debug('Failed to check for updates.');
    }
  }

  void _showUpdateNotice(FvmRelease latestRelease, Version currentVersion) {
    final updateAvailableLabel = lightYellow.wrap('Update available!');
    final currentVersionLabel = lightCyan.wrap(packageVersion);
    final latestVersionLabel = lightCyan.wrap(
      latestRelease.version.toString(),
    );

    logger
      ..info()
      ..info(
        '$updateAvailableLabel $currentVersionLabel \u2192 $latestVersionLabel',
      )
      ..info();

    if (latestRelease.version.major <= currentVersion.major) return;

    logger
      ..info(
        'FVM ${latestRelease.version.major} is distributed as a standalone '
        'CLI and is no longer published to pub.dev.',
      )
      ..info('Migration guide: $kFvmMigrationGuideUrl')
      ..info();
  }

  /// Checks for deprecated environment variables and shows warnings
  void _checkDeprecatedEnvironmentVariables() {
    // Check for deprecated variables (no longer supported)
    final deprecatedVars = {'FVM_GIT_CACHE': 'FVM_FLUTTER_URL'};

    // Check for legacy variables (still supported but discouraged)
    final legacyVars = {'FVM_HOME': 'FVM_CACHE_PATH'};

    var hasDeprecated = false;
    for (final entry in deprecatedVars.entries) {
      if (context.environment.containsKey(entry.key)) {
        if (!hasDeprecated) {
          logger.warn('Deprecated environment variables detected:');
          hasDeprecated = true;
        }
        logger.warn('  ${entry.key} → Use ${entry.value} instead');
      }
    }

    var hasLegacy = false;
    for (final entry in legacyVars.entries) {
      if (context.environment.containsKey(entry.key) &&
          !context.environment.containsKey(entry.value)) {
        if (!hasLegacy) {
          logger.info('Legacy environment variables detected:');
          hasLegacy = true;
        }
        logger.info('  ${entry.key} → Consider using ${entry.value}');
      }
    }

    if (hasDeprecated || hasLegacy) logger.info('');
  }

  Logger get logger => context.get();

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
    } on ForceExit catch (e) {
      logger.info(e.message);

      return e.exitCode;
    } on AppDetailedException catch (err, stackTrace) {
      logger
        ..fail(err.message)
        ..err()
        ..err(err.info);
      logger.logTrace(stackTrace);

      return ExitCode.unavailable.code;
    } on FileSystemException catch (err, stackTrace) {
      if (checkIfNeedsPrivilegePermission(err)) {
        logger
          ..info()
          ..fail('Requires administrator privileges to run this command.')
          ..info();

        logger.notice(
          "You don't have the required privileges to run this command.\n"
          "Try running with sudo or administrator privileges.\n"
          "If you are on Windows, you can turn on developer mode: https://bit.ly/3vxRr2M",
        );

        return ExitCode.noPerm.code;
      }

      logger
        ..err(err.message)
        ..info()
        ..err('Path: ${err.path}');
      logger.logTrace(stackTrace);

      return ExitCode.ioError.code;
    } on AppException catch (err) {
      logger.fail(err.message);

      return ExitCode.data.code;
    } on ProcessException catch (e) {
      logger
        ..info()
        ..err(e.toString())
        ..info();

      return e.errorCode;
    } on UsageException catch (err) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      logger
        ..err(err.message)
        ..info()
        ..info(err.usage);

      return ExitCode.usage.code;
    } on Exception catch (err, stackTrace) {
      logger
        ..info()
        ..err(err.toString());

      logger.logTrace(stackTrace);

      return ExitCode.unavailable.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Verbose logs
    logger
      ..debug('')
      ..debug('Argument information:');

    final commandName = topLevelResults.command?.name;
    if (commandName == 'completion' || commandName == 'api') {
      return await super.runCommand(topLevelResults) ?? ExitCode.success.code;
    }

    final hasTopLevelOption = topLevelResults.options.any(
      (e) => topLevelResults.wasParsed(e),
    );

    if (hasTopLevelOption) {
      logger.debug('  Top level options:');
      for (final option in topLevelResults.options) {
        if (topLevelResults.wasParsed(option)) {
          logger.debug('  - $option: ${topLevelResults[option]}');
        }
      }
      logger.debug('');
    }

    if (topLevelResults.command != null) {
      final commandResult = topLevelResults.command!;
      logger.debug('Command: ${commandResult.name}');

      // Check if any command option was parsed
      final hasCommandOption = commandResult.options.any(
        (e) => commandResult.wasParsed(e),
      );

      if (hasCommandOption) {
        logger.debug('  Command options:');
        for (final option in commandResult.options) {
          if (commandResult.wasParsed(option)) {
            logger.debug('    - $option: ${commandResult[option]}');
          }
        }
      }

      logger.debug('');
    }

    // Check for deprecated environment variables
    _checkDeprecatedEnvironmentVariables();

    final updateCheck = _checkForUpdates();

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      logger.info(packageVersion);
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    final updateNotice = await updateCheck;
    updateNotice?.call();

    return exitCode;
  }

  /// Disable auto-install of shell completions to avoid PathAccessException
  /// in managed environments (Nix/Home Manager) where shell configs are read-only.
  /// Users can still manually install completions via `fvm completion install`.
  @override
  bool get enableAutoInstall => false;
}
