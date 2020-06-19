import 'package:args/command_runner.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';

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
    final version = argResults.arguments[0].toLowerCase();

    final isValidInstall = isFlutterVersionInstalled(version);

    if (!isValidInstall) {
      throw Exception('Flutter SDK: $version is not installed');
    }

    final progress = logger.progress('Removing $version');
    try {
      flutterSdkRemove(version);
      finishProgress(progress);
    } on Exception {
      rethrow;
    }
  }
}
