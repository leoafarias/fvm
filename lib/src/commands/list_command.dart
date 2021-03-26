import 'package:fvm/constants.dart';
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
  final description = 'Lists installed Flutter SDK Version';

  /// Constructor
  ListCommand();

  @override
  Future<int> run() async {
    final cacheVersions = await CacheService.getAll();

    if (cacheVersions.isEmpty) {
      FvmLogger.info(
        '''
        No SDKs have been installed yet. Flutter 
        SDKs installed outside of fvm will not be displayed.
        ''',
      );
      return ExitCode.success.code;
    }

    // Print where versions are stored
    print('Versions path:  ${yellow.wrap(kVersionsDir.path)}');

    // Get current project
    final project = await FlutterAppService.findAncestor();

    for (var version in cacheVersions) {
      printVersionStatus(version, project);
    }

    return ExitCode.success.code;
  }
}
