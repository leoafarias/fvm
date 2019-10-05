import 'package:args/command_runner.dart';

/// Loads Beta Channel SDK
class BetaChannelCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "beta";
  final description = "Downloads Flutter SDK Version from Beta Channel";

  /// Constructor
  BetaChannelCommand();
}
