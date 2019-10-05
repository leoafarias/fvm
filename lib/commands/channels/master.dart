import 'package:args/command_runner.dart';
import 'package:fvm/utils/logger.dart';

/// Loads Master Channel SDK
class MasterChannelCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "master";
  final description = "Downloads Flutter SDK Version from Master Channel";

  /// Constructor
  MasterChannelCommand();
}
