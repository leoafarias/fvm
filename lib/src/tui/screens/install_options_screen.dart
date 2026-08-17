import 'dart:async';

import 'package:noir/noir.dart';

import '../fvm_tui_controller.dart';
import '../fvm_tui_models.dart';
import '../theme/fvm_tui_theme.dart';
import '../widgets/terminal_primitives.dart';

final class InstallOptionsScreen extends StatefulWidget {
  const InstallOptionsScreen({
    required this.controller,
    required this.version,
    required this.onBack,
    super.key,
  });

  final FvmTuiController controller;
  final String version;
  final VoidCallback onBack;

  @override
  State<InstallOptionsScreen> createState() => InstallOptionsScreenState();
}

final class InstallOptionsScreenState extends State<InstallOptionsScreen> {
  var _selectedOption = 0;
  var _useGitCache = true;
  var _runSetup = true;
  var _useAfterInstall = false;
  var _force = false;

  InstallRequest get request => (
    version: widget.version,
    useGitCache: _useGitCache,
    runSetup: _runSetup,
    useAfterInstall: _useAfterInstall,
    force: _force,
  );

  void toggle(int index) {
    if (!mounted || index < 0 || index > 3) return;
    setState(() {
      _selectedOption = index;
      switch (index) {
        case 0:
          _useGitCache = !_useGitCache;
        case 1:
          _runSetup = !_runSetup;
        case 2:
          _useAfterInstall = !_useAfterInstall;
        case 3:
          _force = !_force;
      }
    });
  }

  Future<void> install() => widget.controller.install(request);

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!event.isPress) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _selectedOption = (_selectedOption - 1).clamp(0, 3));

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selectedOption = (_selectedOption + 1).clamp(0, 3));

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      toggle(_selectedOption);

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      unawaited(install());

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onBack();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: _handleKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 1,
      children: [
        Text('Install ${widget.version}', style: FvmTuiTextStyles.heading),
        DetailRow(label: 'Release', value: widget.version),
        ToggleRow(
          label: 'Use Git cache',
          value: _useGitCache,
          focused: _selectedOption == 0,
        ),
        ToggleRow(
          label: 'Run Flutter setup',
          value: _runSetup,
          focused: _selectedOption == 1,
        ),
        ToggleRow(
          label: 'Use after install',
          value: _useAfterInstall,
          focused: _selectedOption == 2,
        ),
        ToggleRow(label: 'Force', value: _force, focused: _selectedOption == 3),
        const KeyHint(keyLabel: 'Space', description: 'toggle'),
        const KeyHint(keyLabel: 'Enter', description: 'install'),
        const KeyHint(keyLabel: 'Escape', description: 'back'),
      ],
    ),
  );
}
