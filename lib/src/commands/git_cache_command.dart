import 'package:args/args.dart';
import 'package:fvm/src/services/git_tools.dart';

import 'base_command.dart';

/// Executes scripts with the configured Flutter SDK
class GitCacheCommand extends BaseCommand {
  @override
  final name = 'git-cache';
  @override
  final description = 'Creates a local git cache';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  GitCacheCommand();

  @override
  Future<int> run() async {
    await GitTools.updateFlutterRepoMirror();
    return 0;
  }
}
