import 'package:mason_logger/mason_logger.dart';

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

  @override
  List<String> get aliases => ['ls'];

  /// Constructor
  ListCommand();

  @override
  Future<int> run() async {
    final cacheVersions = await CacheService.getAllVersions();
    ctx.fvmVersionsDir.path;
    if (cacheVersions.isEmpty) {
      logger.info(
        'No SDKs have been installed yet. Flutter. SDKs'
        ' installed outside of fvm will not be displayed.',
      );
      return ExitCode.success.code;
    }

    // Print where versions are stored
    logger
      ..info('Cache directory:  ${cyan.wrap(ctx.fvmVersionsDir.path)}')
      ..spacer;

    // Get current project
    final project = await ProjectService.findAncestor();

    for (var version in cacheVersions) {
      await printVersionStatus(version, project);
    }

    return ExitCode.success.code;
  }
}
