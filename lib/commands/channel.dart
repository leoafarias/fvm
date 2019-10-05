import 'package:args/command_runner.dart';
import 'package:fvm/utils/logger.dart';
import 'package:fvm/commands/channels/master.dart';
import 'package:fvm/commands/channels/dev.dart';
import 'package:fvm/commands/channels/beta.dart';
import 'package:fvm/commands/channels/stable.dart';

/// Loads SDK from channel
class ChannelCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  final name = "channel";
  final description = "Downloads Flutter SDK Version";

  /// Constructor
  ChannelCommand() {
    addSubcommand(MasterChannelCommand());
    addSubcommand(StableChannelCommand());
    addSubcommand(DevChannelCommand());
    addSubcommand(BetaChannelCommand());
  }
}
