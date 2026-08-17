import 'package:noir/noir.dart';

import '../fvm_tui_controller.dart';
import '../fvm_tui_models.dart';
import '../theme/fvm_tui_theme.dart';
import '../widgets/terminal_primitives.dart';

final class InstallProgressScreen extends StatelessWidget {
  const InstallProgressScreen({required this.controller, super.key});

  final FvmTuiController controller;

  void cancel() => controller.cancelInstall();

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event.isPress &&
        event.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyC &&
        controller.hasActiveInstall) {
      cancel();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  InstallProgressUpdate _latestFor(InstallPhase phase) {
    for (final update in controller.installProgress.reversed) {
      if (update.phase == phase) return update;
    }

    return (
      phase: phase,
      status: OperationStatus.pending,
      detail: 'Pending',
      exactPercent: null,
    );
  }

  String _label(InstallPhase phase) => switch (phase) {
    InstallPhase.ensureCache => 'Prepare cache',
    InstallPhase.acquireLock => 'Acquire lock',
    InstallPhase.cloneSdk => 'Clone SDK',
    InstallPhase.validateRevision => 'Validate revision',
    InstallPhase.setupFlutter => 'Setup Flutter',
    InstallPhase.linkProject => 'Link project',
  };

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: _handleKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 1,
      children: [
        Text('Install progress', style: FvmTuiTextStyles.heading),
        ...InstallPhase.values.map((phase) {
          final update = _latestFor(phase);

          return ProgressStep(
            label: _label(phase),
            status: update.status,
            detail: update.detail,
            exactPercent: update.exactPercent,
          );
        }),
        Text('Output', style: FvmTuiTextStyles.muted),
        SizedBox(
          height: 8,
          child: ScrollBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: controller.operationEvents
                  .map((event) => Text(event, style: FvmTuiTextStyles.muted))
                  .toList(),
            ),
          ),
        ),
        KeyHint(
          keyLabel: 'Ctrl+C',
          description: controller.hasActiveInstall
              ? 'cancel install safely'
              : 'exit',
        ),
      ],
    ),
  );
}
