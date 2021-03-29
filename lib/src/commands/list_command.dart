import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';

import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_app_service.dart';
import 'package:fvm/src/utils/console_utils.dart';

import 'package:fvm/src/utils/logger.dart';

import 'package:io/ansi.dart';
import 'package:args/command_runner.dart';
import 'package:io/io.dart';

/// List installed SDK Versions
class ListCommand extends Command<int> {
  @override
  final name = 'list';

  @override
  final description = 'Lists installed Flutter SDK Versions';

  /// Constructor
  ListCommand();

  @override
  Future<int> run() async {
    final cacheVersions = await CacheService.getAllVersions();

    if (cacheVersions.isEmpty) {
      throw const FvmUsageException(
        'No SDKs have been installed yet. Flutter. SDKs installed outside of fvm will not be displayed.',
      );
    }

    // Print where versions are stored
    FvmLogger.info('Cache Path:  ${yellow.wrap(CacheService.cacheDir.path)}');
    FvmLogger.spacer();

    // Get current project
    final project = await FlutterAppService.findAncestor();

    for (var version in cacheVersions) {
      await printVersionStatus(version, project);
    }

    FvmLogger.spacer();

    return ExitCode.success.code;
  }
}
