import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/git_tools.dart';
import 'package:fvm/src/utils/pretty_print.dart';

import '../utils/pretty_print.dart';

Future<void> installWorkflow(String version) async {
  try {
    assert(version != null);

    // If it's installed correctly just return and use cached
    if (await LocalVersionRepo.isInstalled(version)) {
      PrettyPrint.success('Version: $version - already installed.');
      return;
    }

    PrettyPrint.success('Installing version: $version:');

    await runGitClone(version);

    PrettyPrint.success('Version installed: $version:');
  } on Exception {
    throw InternalError('Could not install <$version>');
  }
}
