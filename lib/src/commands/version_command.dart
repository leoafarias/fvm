import 'package:fvm/src/version.dart';
import 'package:args/command_runner.dart';

/// Returns Version for Flutter command
class VersionCommand extends Command {
  @override
  String get name => 'version';

  @override
  String get description => 'Prints the currently-installed version of FVM';

  @override
  void run() {
    print(packageVersion);
  }
}
