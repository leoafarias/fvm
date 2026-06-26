part of '../tui_command.dart';

class _TuiHeader extends StatelessWidget {
  const _TuiHeader({
    required this.totalCount,
    required this.needsSetupCount,
    required this.projectVersion,
    required this.globalVersion,
  });

  final int totalCount;
  final int needsSetupCount;
  final String? projectVersion;
  final String? globalVersion;

  int get readyCount => totalCount - needsSetupCount;

  Widget _metric({
    required String label,
    required String value,
    required Color color,
  }) =>
      Row(
        spacing: 1,
        children: [
          Text('$label:', style: const TextStyle(color: _TuiTheme.muted)),
          Text(value, style: TextStyle(color: color)),
        ],
      );

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _TuiTheme.panel,
          border: Border.all(color: _TuiTheme.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'FVM SDK Cache',
                  style: TextStyle(
                    color: _TuiTheme.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Expanded(child: SizedBox()),
                Text(
                  '$readyCount ready / $totalCount cached',
                  style: const TextStyle(color: _TuiTheme.muted),
                ),
              ],
            ),
            Row(
              spacing: 2,
              children: [
                _metric(
                  label: 'Project',
                  value: projectVersion ?? '-',
                  color: _TuiTheme.project,
                ),
                _metric(
                  label: 'Global',
                  value: globalVersion ?? '-',
                  color: _TuiTheme.global,
                ),
                if (needsSetupCount > 0)
                  Text(
                    'Setup needed: $needsSetupCount',
                    style: const TextStyle(color: _TuiTheme.warning),
                  ),
              ],
            ),
          ],
        ),
      );
}
