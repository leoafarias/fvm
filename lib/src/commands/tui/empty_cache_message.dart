part of '../tui_command.dart';

class _EmptyCacheMessage extends StatelessWidget {
  const _EmptyCacheMessage();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _TuiTheme.panel,
          border: Border.all(color: _TuiTheme.border),
        ),
        padding: const EdgeInsets.all(1),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No cached Flutter SDKs',
              style: TextStyle(
                color: _TuiTheme.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Run fvm install stable, or preview this interface with fvm tui --sample.',
              style: TextStyle(color: _TuiTheme.text),
            ),
          ],
        ),
      );
}
