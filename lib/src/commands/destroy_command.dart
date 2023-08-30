import 'package:fvm/src/utils/logger.dart';
import 'package:io/io.dart';

import '../services/context.dart';
import 'base_command.dart';

/// Destroy FVM cache by deleting all Flutter SDK versions
class DestroyCommand extends BaseCommand {
  @override
  final name = 'destroy';

  @override
  final description = 'Destroy FVM cache by deleting FVM directory';

  /// Constructor
  DestroyCommand();

  @override
  Future<int> run() async {
    if (logger.confirm(
      'Are you sure you want to destroy the directory "${ctx.fvmHome.path}" ?',
      defaultValue: false,
    )) {
      if (ctx.fvmHome.existsSync()) {
        ctx.fvmHome.deleteSync(recursive: true);
        logger.success('FVM Directory ${ctx.fvmHome.path}\n has been deleted');
      }
    }

    return ExitCode.success.code;
  }
}
