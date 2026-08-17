import '../tui/fvm_tui_launcher.dart';
import '../utils/context.dart';
import '../utils/exceptions.dart';
import 'base_command.dart';

typedef FvmTuiLauncher = Future<int> Function(FvmContext context);

final class TuiCommand extends BaseFvmCommand {
  final FvmTuiLauncher _launcher;

  TuiCommand(super.context, {FvmTuiLauncher launcher = launchFvmTui})
    : _launcher = launcher;

  @override
  Future<int> run() {
    if (context.skipInput) {
      throw ForceExit.unavailable('fvm tui requires an interactive terminal.');
    }

    return _launcher(context);
  }

  @override
  String get name => 'tui';

  @override
  String get description => 'Opens the interactive FVM terminal interface';
}
