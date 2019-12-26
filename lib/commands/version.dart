import 'dart:io';
import 'package:fvm/src/version.dart';
import 'package:yaml/yaml.dart';
import 'package:args/command_runner.dart';

/// Returns Version for Flutter command
class VersionCommand extends Command {
  @override
  String get name => 'version';

  @override
  String get description => 'Prints the currently-installed version of FVM';

  @override
  run() {
    print(packageVersion);
  }
}
