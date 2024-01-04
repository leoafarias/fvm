import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/version.g.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

class UpdateCommand extends Command<int> {
  static const String commandName = 'update';

  final PubUpdater _pubUpdater;

  UpdateCommand({PubUpdater? pubUpdater})
      : _pubUpdater = pubUpdater ?? PubUpdater();

  @override
  Future<int> run() async {
    final updateCheckProgress = logger.progress('Checking for updates');
    final String latestVersion;
    try {
      latestVersion = await _pubUpdater.getLatestVersion(kPackageName);
    } catch (error) {
      updateCheckProgress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    }
    updateCheckProgress.complete('Checked for updates');

    final isUpToDate = packageVersion == latestVersion;
    if (isUpToDate) {
      logger.info('CLI is already at the latest version.');
      return ExitCode.success.code;
    }

    final updateProgress = logger.progress('Updating to $latestVersion');

    late final ProcessResult result;
    try {
      result = await _pubUpdater.update(
        packageName: kPackageName,
        versionConstraint: latestVersion,
      );
    } catch (error) {
      updateProgress.fail();
      logger.err('$error');
      return ExitCode.software.code;
    }

    if (result.exitCode != ExitCode.success.code) {
      updateProgress.fail();
      logger.err('Error updating CLI: ${result.stderr}');
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
