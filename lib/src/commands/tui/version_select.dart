part of '../tui_command.dart';

class _VersionSelect extends StatelessWidget {
  const _VersionSelect({
    required this.choices,
    required this.focusNode,
    required this.onChanged,
    required this.onSelect,
  });

  final List<FvmTuiVersionChoice> choices;
  final FocusNode focusNode;
  final void Function(int index) onChanged;
  final void Function(FvmTuiVersionChoice choice) onSelect;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _TuiTheme.panelAlt,
          border: Border.all(color: _TuiTheme.borderActive),
        ),
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Installed SDKs',
                  style: TextStyle(
                    color: _TuiTheme.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Expanded(child: SizedBox()),
                Text(
                  '${choices.length} total',
                  style: const TextStyle(color: _TuiTheme.muted),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Select<FvmTuiVersionChoice>(
              focusNode: focusNode,
              autofocus: true,
              height: 12,
              showScrollIndicator: true,
              color: _TuiTheme.text,
              descriptionColor: _TuiTheme.muted,
              selectedBackgroundColor: _TuiTheme.selection,
              selectedTextColor: Color.white,
              options: [
                for (final choice in choices)
                  SelectOption(
                    name: choice.rowLabel,
                    description: choice.rowDescription,
                    value: choice,
                  ),
              ],
              onChanged: (index, option) => onChanged(index),
              onSelect: (index, option) => onSelect(option.value!),
            ),
          ],
        ),
      );
}
