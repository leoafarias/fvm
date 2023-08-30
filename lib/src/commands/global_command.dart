import 'package:io/io.dart';

import '../utils/logger.dart';
import 'base_command.dart';

/// Removes Flutter SDK
class GlobalCommand extends BaseCommand {
  @override
  final name = 'global';

  @override
  final description = 'Global command is no longer supported';

  /// Constructor
  GlobalCommand();

  @override
  String get invocation => 'fvm global {version}';

  @override
  Future<int> run() async {
    logger.success(
      '''This command has been deprecated on version FVM 3.0.
      We recomend using a standard Flutter SDK setup for global Flutter version,
      and using FVM for project specific Flutter versions.\n
      For more information visit: https://fvm.app/docs/guides/global_version''',
    );

    return ExitCode.success.code;
  }
}
