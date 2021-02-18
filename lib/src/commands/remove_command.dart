import 'package:args/command_runner.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';

import 'package:fvm/src/local_versions/local_version.repo.dart';

import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/remove_version.workflow.dart';

/// Removes Flutter SDK
class RemoveCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'remove';

  @override
  final description = 'Removes Flutter SDK Version';

  /// Constructor
  RemoveCommand() {
    // TODO: Remove these options
    argParser
      ..addOption('channel', abbr: 'c', help: 'Fluter channel to remove ')
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Version number to remove. i.e: 1.8.1',
      );
  }

  @override
  void run() async {
    final version = argResults.rest[0].toLowerCase();
    final validVersion = await inferFlutterVersion(version);
    final isValidInstall = await LocalVersionRepo.isInstalled(validVersion);

    if (!isValidInstall) {
      FvmLogger.info('Flutter SDK: $validVersion is not installed');
      return;
    }

    await removeWorkflow(validVersion);
  }
}
