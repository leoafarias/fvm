// ignore_for_file: prefer-single-widget-per-file

import 'package:noir/noir.dart';

import '../fvm_tui_models.dart';
import '../theme/fvm_tui_theme.dart';
import 'terminal_primitives.dart';

final class ScreenShell extends StatelessWidget {
  const ScreenShell({
    required this.layoutMode,
    required this.route,
    required this.content,
    required this.onNavigate,
    required this.onBack,
    super.key,
  });

  final FvmTuiLayoutMode layoutMode;
  final FvmTuiRoute route;
  final Widget content;
  final void Function(FvmTuiRoute route) onNavigate;
  final VoidCallback onBack;

  Widget _navigation() => Container(
    color: FvmTuiColors.panel,
    padding: const EdgeInsets.only(top: 1),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 1,
      children: [
        for (final entry in _navigationRoutes)
          NavigationItem(
            label: entry.label,
            shortcut: entry.shortcut,
            selected: route == entry.route,
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    color: FvmTuiColors.canvas,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(route: route),
        Expanded(
          child: layoutMode == FvmTuiLayoutMode.wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 20, child: _navigation()),
                    Expanded(
                      child: Container(
                        color: FvmTuiColors.surface,
                        padding: const EdgeInsets.all(1),
                        child: content,
                      ),
                    ),
                  ],
                )
              : Container(
                  color: FvmTuiColors.surface,
                  padding: const EdgeInsets.all(1),
                  child: content,
                ),
        ),
        const _Footer(),
      ],
    ),
  );
}

const List<({FvmTuiRoute route, String shortcut, String label})>
_navigationRoutes = [
  (route: FvmTuiRoute.versions, shortcut: '1', label: 'Versions'),
  (route: FvmTuiRoute.releases, shortcut: '2', label: 'Releases'),
  (route: FvmTuiRoute.doctor, shortcut: '3', label: 'Doctor'),
  (route: FvmTuiRoute.configuration, shortcut: '4', label: 'Configuration'),
];

final class _Header extends StatelessWidget {
  const _Header({required this.route});

  final FvmTuiRoute route;

  @override
  Widget build(BuildContext context) => Container(
    color: FvmTuiColors.panel,
    padding: const EdgeInsets.symmetric(horizontal: 1),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('FVM', style: FvmTuiTextStyles.accent, maxLines: 1),
        Text(_routeLabel(route), style: FvmTuiTextStyles.muted, maxLines: 1),
      ],
    ),
  );
}

final class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Container(
    color: FvmTuiColors.panel,
    padding: const EdgeInsets.symmetric(horizontal: 1),
    child: const Row(
      spacing: 2,
      children: [
        KeyHint(keyLabel: 'Tab', description: 'focus'),
        KeyHint(keyLabel: 'Ctrl+Q', description: 'quit'),
      ],
    ),
  );
}

String _routeLabel(FvmTuiRoute route) => switch (route) {
  FvmTuiRoute.versions => 'Versions',
  FvmTuiRoute.releases => 'Releases',
  FvmTuiRoute.useVersion => 'Use version',
  FvmTuiRoute.installOptions => 'Install options',
  FvmTuiRoute.installProgress => 'Install progress',
  FvmTuiRoute.doctor => 'Doctor',
  FvmTuiRoute.configuration => 'Configuration',
};
