import 'package:io/io.dart';

import '../../exceptions.dart';
import 'helpers.dart';
import 'logger.dart';

/// Guards against certain action by validatin and throwing errors
class Guards {
  Guards._();

  /// Check if can execute path or throws error
  static Future<void> canExecute(String execPath, List<String> args) async {
    if (!await isExecutable(execPath)) {
      throw FvmInternalError('Cannot execute $execPath');
    }
    if (shouldRunDetached(args)) {
      FvmLogger.spacer();
      FvmLogger.info(
        'This command "${args.join(" ")}" will modify FVM installation.',
      );
      FvmLogger.info(
        '''Because of that, it is recommended you run the following command''',
      );
      FvmLogger.info(
        '''in your terminal directly pointing to the cached version.''',
      );
      FvmLogger.spacer();
      FvmLogger.fine("$execPath ${args.join(' ')}");

      FvmLogger.spacer();

      FvmLogger.info(
        '''If after this command FVM cannot be found in your terminal. Please run the following:''',
      );

      FvmLogger.spacer();
      FvmLogger.fine("$execPath pub global activate fvm");

      throw FvmUsageException('Command needs to run outside of FVM proxy');
    }
  }
}
