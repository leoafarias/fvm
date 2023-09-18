import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:io/io.dart';

import '../utils/context.dart';
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
      'Are you sure you want to destroy the directory "${ctx.fvmDir}" ?',
      defaultValue: false,
    )) {
      final fvmDir = Directory(ctx.fvmDir);
      if (fvmDir.existsSync()) {
        fvmDir.deleteSync(recursive: true);
        logger.complete(
          '$kPackageName Directory ${fvmDir.path} has been deleted',
        );
      }
    }

    return ExitCode.success.code;
  }
}
