import 'package:args/command_runner.dart';

/// Loads Dev Channel SDK
class DevChannelCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "dev";
  final description = "Downloads Flutter SDK Version from Dev Channel";

  /// Constructor
  DevChannelCommand();
}
