import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

import '../utils/constants.dart';
import '../utils/context.dart';
import '../version.dart';

class UpdateCommand extends Command<int> {
  static const String commandName = 'update';

  final PubUpdater _pubUpdater;

  UpdateCommand({PubUpdater? pubUpdater})
      : _pubUpdater = pubUpdater ?? PubUpdater();

  @override
  Future<int> run() async {
    final updateCheckProgress =
        ctx.loggerService.progress('Checking for updates');
    final String latestVersion;
    try {
      latestVersion = await _pubUpdater.getLatestVersion(kPackageName);
    } catch (error) {
      updateCheckProgress.fail();
      ctx.loggerService.err('$error');

      return ExitCode.software.code;
    }
    updateCheckProgress.complete('Checked for updates');

    final isUpToDate = packageVersion == latestVersion;
    if (isUpToDate) {
      ctx.loggerService.success('You are already using the latest version.');

      return ExitCode.success.code;
    }

    final updateProgress =
        ctx.loggerService.progress('Updating to $latestVersion');

    late final ProcessResult result;
    try {
      result = await _pubUpdater.update(
        packageName: kPackageName,
        versionConstraint: latestVersion,
      );
    } catch (error) {
      updateProgress.fail();
      ctx.loggerService.err('$error');

      return ExitCode.software.code;
    }

    if (result.exitCode != ExitCode.success.code) {
      updateProgress.fail();
      ctx.loggerService.err('Error updating CLI: ${result.stderr}');

      return ExitCode.software.code;
    }

    updateProgress.complete('Updated to $latestVersion');

    return ExitCode.success.code;
  }

  @override
  String get description => 'Update the CLI.';

  @override
  String get name => commandName;
}
