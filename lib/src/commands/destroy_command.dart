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
  DestroyCommand(super.context) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Bypass confirmation prompt (use with caution)',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final force = boolArg('force');

    // Proceed if force flag is used OR user confirms
    // When skipInput is true, default to false (safe default for destructive operation)
    final shouldProceed =
        force ||
        logger.confirm(
          'Are you sure you want to destroy the FVM cache directory and references?\n'
          'This action cannot be undone. Do you want to proceed?',
          defaultValue: false,
        );

    if (shouldProceed) {
      if (context.versionsCachePath.dir.existsSync()) {
        context.versionsCachePath.dir.deleteSync(recursive: true);
        logger.success(
          'FVM Directory ${context.versionsCachePath} has been deleted',
        );
      }
    }

    return ExitCode.success.code;
  }
}
