part of '../tui_command.dart';

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Row(
        spacing: 1,
        children: [
          SizedBox(
            width: 8,
            child: Text(
              label,
              style: const TextStyle(color: _TuiTheme.muted),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: value.isEmpty
                    ? _TuiTheme.muted
                    : (valueColor ?? _TuiTheme.text),
              ),
            ),
          ),
        ],
      );
}
