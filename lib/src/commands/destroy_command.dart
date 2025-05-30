import 'package:io/io.dart';

import '../utils/extensions.dart';
import 'base_command.dart';

/// Destroy FVM cache by deleting all Flutter SDK versions
class DestroyCommand extends BaseFvmCommand {
  @override
  final name = 'destroy';

  @override
  final description =
      'Completely removes the FVM cache and all cached Flutter SDK versions';

  /// Constructor
  DestroyCommand(super.context);

  @override
  Future<int> run() async {
    if (logger.confirm(
      'Are you sure you want to destroy the FVM cache directory and references?\n'
      'This action cannot be undone. Do you want to proceed?',
      defaultValue: false,
    )) {
      if (context.versionsCachePath.dir.existsSync()) {
        context.versionsCachePath.dir.deleteSync(recursive: true);
        logger.success(
          'FVM Directory ${context.versionsCachePath}\n has been deleted',
        );
      }
    }

    return ExitCode.success.code;
  }
}
