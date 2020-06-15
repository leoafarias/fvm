import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';
import 'package:fvm/utils/version_installer.dart';
import 'package:io/ansi.dart';

/// Use an installed SDK version
class UseCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'use';

  @override
  final description = 'Which Flutter SDK Version you would like to use';

  /// Constructor
  UseCommand();

  @override
  Future<void> run() async {
    if (argResults.arguments.isEmpty) {
      final instruction = yellow.wrap('fvm use <version>');
      throw Exception('Please provide a version. $instruction');
    }
    final version = argResults.arguments[0];

    final isValidInstall = await isValidFlutterInstall(version);

    if (!isValidInstall) {
      print('Flutter $version is not installed.');
      var inputConfirm = await readInput('Would you like to install it? y/N: ');

      if (inputConfirm.contains('y')) {
        final installProgress = logger.progress('Installing $version');
        await installFlutterVersion(version);
        finishProgress(installProgress);

        await linkProjectFlutterDir(version);
        logger.stdout(green.wrap('$version is active'));
      } else {
        print('Done');
      }
    } else {
      logger.stdout(green.wrap('$version is active'));
    }
  }
}
