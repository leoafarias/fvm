import 'dart:io';

import 'package:io/io.dart';

import '../../exceptions.dart';
import '../services/context.dart';
import 'helpers.dart';

/// Guards against certain action by validatin and throwing errors
class Guards {
  /// Check if can execute path or throws error
  static Future<void> canExecute(String execPath) async {
    if (!await isExecutable(execPath)) {
      throw FvmInternalError('Cannot execute $execPath');
    }
  }

  /// Checks if user can create symlink
  static Future<void> canSymlink() async {
    try {
      await createLink(ctx.testLinkSource, ctx.testLinkTarget);
    } on Exception {
      var message = '';
      if (Platform.isWindows) {
        message = 'On Windows FVM requires to run as an administrator '
            'run as an administrator or turn on developer mode: https://bit.ly/3vxRr2M';
      }

      throw FvmUsageException(
        "Seems you don't have the required permissions on ${ctx.fvmHome.path}"
        ' $message',
      );
    } finally {
      // Clean up
      if (await ctx.testLinkSource.exists()) {
        await ctx.testLinkSource.delete();
      }
      if (await ctx.testLinkTarget.exists()) {
        await ctx.testLinkTarget.delete();
      }
    }
  }
}
