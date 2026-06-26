part of '../tui_command.dart';

class _VersionDetails extends StatelessWidget {
  const _VersionDetails({required this.version});

  final FvmTuiVersionChoice version;

  Color get _healthColor {
    if (version.needsSetup) return _TuiTheme.warning;
    if (version.isProject) return _TuiTheme.project;
    if (version.isGlobal) return _TuiTheme.global;

    return _TuiTheme.accent;
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _TuiTheme.panel,
          border: Border.all(color: _TuiTheme.border),
        ),
        padding: const EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              version.titleLabel,
              style: TextStyle(
                color: _healthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              version.statusSummaryLabel,
              style: const TextStyle(color: _TuiTheme.muted),
            ),
            const SizedBox(height: 1),
            _Field(
              label: 'State',
              value: version.healthLabel,
              valueColor: _healthColor,
            ),
            _Field(label: 'Kind', value: version.kind),
            _Field(label: 'Channel', value: version.channel),
            _Field(label: 'Flutter', value: version.flutterVersion),
            _Field(label: 'Dart', value: version.dartVersion),
            _Field(label: 'Released', value: version.releaseDate),
            _Field(label: 'Cache', value: version.cachePathLabel),
          ],
        ),
      );
}
