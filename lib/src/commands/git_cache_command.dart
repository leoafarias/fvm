import 'package:args/command_runner.dart';
import 'package:fvm/src/services/git_tools.dart';
import 'package:io/io.dart';

/// Use an installed SDK version
class GitCacheCommand extends Command<int> {
  @override
  final name = 'git-cache';

  @override
  String description = 'Creates a cache of the Flutter repo';

  @override
  String get summary => '$invocation $description';

  /// Constructor
  GitCacheCommand();

  @override
  Future<int> run() async {
    await GitTools.updateCache();
    return ExitCode.success.code;
  }
}
