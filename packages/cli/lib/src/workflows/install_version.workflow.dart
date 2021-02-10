import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/git_tools.dart';
import 'package:fvm/src/utils/confirm.dart';
import 'package:fvm/src/utils/logger.dart';

import '../utils/logger.dart';

Future<void> installWorkflow(String version) async {
  try {
    assert(version != null);

    // If it's installed correctly just return and use cached
    final isVersionInstalled = await LocalVersionRepo.isInstalled(version);

    if (isVersionInstalled) {
      logger.trace('Version: $version - already installed.');
      return;
    }

    FvmLogger.info('Flutter $version is not installed.');
    // Install if input is confirmed
    if (await confirm('Would you like to install it?')) {
      FvmLogger.fine('Installing version: $version');
      await runGitClone(version);
      FvmLogger.fine('Version installed: $version');
    }
  } on Exception catch (err) {
    logger.trace(err.toString());
    throw InternalError('Could not install <$version>');
  }
}
