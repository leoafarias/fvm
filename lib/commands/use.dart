import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';
import 'package:fvm/utils/version_installer.dart';
import 'package:io/ansi.dart';
import 'package:path/path.dart' as path;

/// Use an installed SDK version
class UseCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'use';

  @override
  final description = 'Which Flutter SDK Version you would like to use';

  /// Constructor
  UseCommand() {
    argParser
      ..addFlag(
        'global',
        help:
            'Creates a symbolic link to the version specified in <FVM_HOME>/default/',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    if (argResults.rest.isEmpty) {
      final instruction = yellow.wrap('fvm use <version>');
      throw Exception('Please provide a version. $instruction');
    }
    final version = argResults.rest[0];

    final isInstalled = await isSdkInstalled(version);

    if (!isInstalled) {
      print('Flutter $version is not installed.');
      var inputConfirm = await readInput('Would you like to install it? Y/n: ');

      // Install if input is 'y'
      if (!inputConfirm.contains('n')) {
        final installProgress = logger.progress('Installing $version');
        await installFlutterVersion(version);
        finishProgress(installProgress);
        logger.stdout(green.wrap('$version is active'));
      }
    } else {
      logger.stdout(green.wrap('$version is active'));
    }

    final useGlobally = argResults['global'] == true;

    if (useGlobally) {
      await linkProjectFlutterDirGlobally(version);
    } else {
      await linkProjectFlutterDir(version);
    }

    if (useGlobally) {
      final flutterSDKBinariesPath = path.join(kDefaultFlutterLink.path, 'bin');
      logger.stdout(green.wrap('$version linked succesfully'));
      logger.stdout(cyan.wrap(
          'Make sure sure to add $flutterSDKBinariesPath to your PATH environment variable'));
    } else {
      logger.stdout(green.wrap('$version is active'));
    }

    finishProgress(progress);
  }
}
