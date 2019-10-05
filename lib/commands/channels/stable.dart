import 'package:args/command_runner.dart';
import 'package:fvm/utils/logger.dart';

/// Loads Stable Channel SDK
class StableChannelCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "stable";
  final description = "Downloads Flutter SDK Version from Stable Channel";

  /// Constructor
  StableChannelCommand();

  // [run] may also return a Future.
  void run() async {
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    logger.stdout('Load Version Stable');
  }
}
