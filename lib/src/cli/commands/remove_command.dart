import 'package:args/command_runner.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';

import 'package:fvm/src/local_versions/local_version.repo.dart';

import 'package:fvm/src/utils/pretty_print.dart';

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
    final flutterVersion = await inferFlutterVersion(version);
    final isValidInstall = await LocalVersionRepo().isInstalled(flutterVersion);

    if (!isValidInstall) {
      throw Exception('Flutter SDK: $flutterVersion is not installed');
    }

    PrettyPrint.success('Removing $flutterVersion');
    try {
      await LocalVersionRepo().remove(flutterVersion);
    } on Exception {
      rethrow;
    }
  }
}
