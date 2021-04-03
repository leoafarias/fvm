import 'package:io/io.dart';

import '../services/git_tools.dart';
import 'base_command.dart';

/// Use an installed SDK version
class GitCacheCommand extends BaseCommand {
  @override
  final name = 'git-cache';

  @override
  String description = 'Creates a cache of the Flutter repo';

  /// Constructor
  GitCacheCommand();

  @override
  Future<int> run() async {
    await GitTools.updateCache();
    return ExitCode.success.code;
  }
}
