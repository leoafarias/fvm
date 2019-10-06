import 'package:args/command_runner.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'package:console/console.dart';

/// List installed SDK Versions
class ListCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "list";
  final description = "Lists installed Flutter SDK Version";

  /// Constructor
  ListCommand();

  Future<void> run() async {
    final choices = await flutterListInstalledSdks();
    //TODO: Check if choices are empty
    final version = Chooser<String>(choices, message: 'Select a version:');
    version.chooseSync();
  }
}
