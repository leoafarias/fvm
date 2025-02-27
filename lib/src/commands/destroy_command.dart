import 'package:io/io.dart';

import '../utils/extensions.dart';
import 'base_command.dart';

/// Destroy FVM cache by deleting all Flutter SDK versions
class DestroyCommand extends BaseCommand {
  @override
  final name = 'destroy';

  @override
  final description = 'Destroy FVM cache by deleting FVM directory';

  /// Constructor
  DestroyCommand(super.controller);

  @override
  Future<int> run() async {
    if (logger.confirm(
      'Are you sure you want to destroy the FVM cache directory and references?\n'
      'This action cannot be undone. Do you want to proceed?',
      defaultValue: false,
    )) {
      if (controller.context.versionsCachePath.dir.existsSync()) {
        controller.context.versionsCachePath.dir.deleteSync(recursive: true);
        logger.success(
          'FVM Directory ${controller.context.versionsCachePath}\n has been deleted',
        );
      }
    }

    return ExitCode.success.code;
  }
}
