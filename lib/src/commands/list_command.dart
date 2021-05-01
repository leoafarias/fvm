import 'package:io/ansi.dart';
import 'package:io/io.dart';

import '../../exceptions.dart';
import '../services/cache_service.dart';
import '../services/context.dart';
import '../services/project_service.dart';
import '../utils/console_utils.dart';
import '../utils/logger.dart';
import 'base_command.dart';

/// List installed SDK Versions
class ListCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Versions';

  /// Constructor
  ListCommand();

  @override
  Future<int> run() async {
    final cacheVersions = await CacheService.getAllVersions();
    ctx.cacheDir.path;
    if (cacheVersions.isEmpty) {
      throw const FvmUsageException(
        'No SDKs have been installed yet. Flutter. SDKs'
        ' installed outside of fvm will not be displayed.',
      );
    }

    // Print where versions are stored
    FvmLogger.info('Cache Directory:  ${yellow.wrap(ctx.cacheDir.path)}\n');

    // Get current project
    final project = await ProjectService.findAncestor();

    for (var version in cacheVersions) {
      await printVersionStatus(version, project);
    }

    return ExitCode.success.code;
  }
}
