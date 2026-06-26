part of '../tui_command.dart';

class _FvmTuiApp extends StatefulWidget {
  const _FvmTuiApp({required this.choices, required this.onComplete});

  final List<FvmTuiVersionChoice> choices;
  final void Function(_TuiCompletion result) onComplete;

  @override
  State<_FvmTuiApp> createState() => _FvmTuiAppState();
}

class _FvmTuiAppState extends State<_FvmTuiApp> {
  final _focusNode = FocusNode();
  int _highlightedIndex = 0;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!event.isPress) {
      return KeyEventResult.ignored;
    }

    if (event.character == 'q' ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onComplete(const _TuiCompletion.cancelled());

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool get _hasChoices => widget.choices.isNotEmpty;

  FvmTuiVersionChoice get _highlighted =>
      widget.choices[_highlightedIndex.clamp(0, widget.choices.length - 1)];

  String? get _projectVersion {
    for (final choice in widget.choices) {
      if (choice.isProject) return choice.name;
    }

    return null;
  }

  String? get _globalVersion {
    for (final choice in widget.choices) {
      if (choice.isGlobal) return choice.name;
    }

    return null;
  }

  int get _needsSetupCount =>
      widget.choices.where((choice) => choice.needsSetup).length;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Container(
          color: _TuiTheme.background,
          padding: const EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TuiHeader(
                totalCount: widget.choices.length,
                needsSetupCount: _needsSetupCount,
                projectVersion: _projectVersion,
                globalVersion: _globalVersion,
              ),
              const SizedBox(height: 1),
              if (_hasChoices)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _VersionSelect(
                          choices: widget.choices,
                          focusNode: _focusNode,
                          onChanged: (index) =>
                              setState(() => _highlightedIndex = index),
                          onSelect: (choice) => widget.onComplete(
                            _TuiCompletion.selected(choice),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _VersionDetails(version: _highlighted),
                      ),
                    ],
                  ),
                )
              else
                const Expanded(child: _EmptyCacheMessage()),
              const SizedBox(height: 1),
              const _TuiFooter(),
            ],
          ),
        ),
      );
}
