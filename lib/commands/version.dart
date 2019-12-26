import 'dart:io';
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
    var f = File("./pubspec.yaml");
    f.readAsString().then((String text) {
      var yaml = loadYaml(text);
      String version = yaml['version'];
      print(version);
    });
  }
}
