import 'package:args/command_runner.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/logger.dart';
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
      final instruction = yellow.wrap('fvm install <version> first.');
      throw Exception(
          'Flutter $version is not installed. Please run $instruction');
    }

    final progress = logger.progress('Activating $version');

    await linkProjectFlutterDir(version);
    logger.stdout(green.wrap('$version is active'));
    finishProgress(progress);
  }
}
