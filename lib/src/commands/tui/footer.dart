part of '../tui_command.dart';

class _TuiFooter extends StatelessWidget {
  const _TuiFooter();

  @override
  Widget build(BuildContext context) => const Text(
        'Arrows/j/k move | PgUp/PgDn/Home/End jump | Enter select | q/Esc cancel',
        style: TextStyle(color: _TuiTheme.muted),
      );
}
