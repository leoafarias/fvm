import 'package:fvm/utils/helpers.dart';
import 'package:io/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/logger.dart';

/// List installed SDK Versions
class ListCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Version';

  /// Constructor
  ListCommand();

  @override
  Future<void> run() async {
    final choices = await flutterListInstalledSdks();

    if (choices.isEmpty) {
      throw 'No SDKs have been installed yet.';
    }

    void printVersions(String version) async {
      if (await isCurrentVersion(version)) {
        version = "$version (current)";
      }
      logger.stdout(green.wrap(version));
    }

    choices.forEach(await printVersions);
  }
}
