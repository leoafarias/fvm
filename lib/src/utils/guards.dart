import '../../exceptions.dart';
import 'package:io/io.dart';

/// Guards against certain action by validatin and throwing errors
class Guards {
  /// Check if can execute path or throws error
  static Future<void> canExecute(String execPath) async {
    if (!await isExecutable(execPath)) {
      throw FvmInternalError('Cannot execute $execPath');
    }
  }
}
