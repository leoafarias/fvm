import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/git_tools.dart';
import 'package:fvm/src/utils/logger.dart';

import '../utils/logger.dart';

Future<void> installWorkflow(String version) async {
  try {
    assert(version != null);

    // If it's installed correctly just return and use cached
    if (await LocalVersionRepo.isInstalled(version)) {
      FvmLogger.fine('Version: $version - already installed.');
      return;
    }

    FvmLogger.fine('Installing version: $version:');

    await runGitClone(version);

    FvmLogger.fine('Version installed: $version:');
  } on Exception {
    throw InternalError('Could not install <$version>');
  }
}
