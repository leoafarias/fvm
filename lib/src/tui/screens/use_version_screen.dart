import 'dart:async';

import 'package:noir/noir.dart';

import '../fvm_tui_controller.dart';
import '../fvm_tui_models.dart';
import '../theme/fvm_tui_theme.dart';
import '../widgets/terminal_primitives.dart';

final class UseVersionScreen extends StatefulWidget {
  const UseVersionScreen({
    required this.controller,
    required this.version,
    required this.onBack,
    super.key,
  });

  final FvmTuiController controller;
  final TuiVersionItem version;
  final VoidCallback onBack;

  @override
  State<UseVersionScreen> createState() => UseVersionScreenState();
}

final class UseVersionScreenState extends State<UseVersionScreen> {
  var _selectedOption = 0;
  var _pin = false;
  var _runPubGet = true;
  var _updateVscode = true;
  var _updateMelos = true;

  UseVersionRequest get request => (
    version: widget.version.id,
    pin: _pin,
    runPubGet: _runPubGet,
    updateVscode: _updateVscode,
    updateMelos: _updateMelos,
    force: false,
    flavor: null,
  );

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
      unawaited(apply());

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onBack();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void toggle(int index) {
    if (!mounted || index < 0 || index > 3) return;
    setState(() {
      _selectedOption = index;
      switch (index) {
        case 0:
          _pin = !_pin;
        case 1:
          _runPubGet = !_runPubGet;
        case 2:
          _updateVscode = !_updateVscode;
        case 3:
          _updateMelos = !_updateMelos;
      }
    });
  }

  Future<void> apply() => widget.controller.useVersion(request);

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: _handleKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 1,
      children: [
        Text('Use ${widget.version.version}', style: FvmTuiTextStyles.heading),
        Container(
          color: FvmTuiColors.selected,
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(widget.version.version, style: FvmTuiTextStyles.accent),
        ),
        DetailRow(label: 'Identity', value: widget.version.id),
        DetailRow(label: 'Channel', value: widget.version.channel),
        ToggleRow(
          label: 'Pin exact channel release',
          value: _pin,
          focused: _selectedOption == 0,
        ),
        ToggleRow(
          label: 'Run pub get',
          value: _runPubGet,
          focused: _selectedOption == 1,
        ),
        ToggleRow(
          label: 'Update VS Code',
          value: _updateVscode,
          focused: _selectedOption == 2,
        ),
        ToggleRow(
          label: 'Update Melos',
          value: _updateMelos,
          focused: _selectedOption == 3,
        ),
        const KeyHint(keyLabel: 'Space', description: 'toggle'),
        const KeyHint(keyLabel: 'Enter', description: 'apply'),
        const KeyHint(keyLabel: 'Escape', description: 'back'),
      ],
    ),
  );
}
