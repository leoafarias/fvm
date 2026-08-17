import 'dart:async';

import 'package:noir/noir.dart';

import 'fvm_tui_controller.dart';
import 'fvm_tui_models.dart';
import 'screens/configuration_screen.dart';
import 'screens/doctor_screen.dart';
import 'screens/install_options_screen.dart';
import 'screens/install_progress_screen.dart';
import 'screens/releases_screen.dart';
import 'screens/use_version_screen.dart';
import 'screens/versions_screen.dart';
import 'theme/fvm_tui_theme.dart';
import 'widgets/screen_shell.dart';

final class FvmTuiApp extends StatefulWidget {
  const FvmTuiApp({
    required this.controller,
    required this.layoutMode,
    required this.onQuit,
    super.key,
  });

  final FvmTuiController controller;
  final FvmTuiLayoutMode layoutMode;
  final VoidCallback onQuit;

  @override
  State<FvmTuiApp> createState() => _FvmTuiAppState();
}

final class _FvmTuiAppState extends State<FvmTuiApp> {
  final _rootFocusNode = FocusNode(debugLabel: 'fvm-tui-root');
  var _controllerRevision = 0;
  late FvmTuiRoute _activeRoute;
  String? _installVersion;
  FvmTuiRoute _installReturnRoute = FvmTuiRoute.versions;

  @override
  void initState() {
    super.initState();
    _activeRoute = widget.controller.route;
    widget.controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final routeChanged = _activeRoute != widget.controller.route;
    _activeRoute = widget.controller.route;
    setState(() => _controllerRevision += 1);
    if (routeChanged) {
      scheduleMicrotask(() {
        if (mounted && _rootFocusNode.isAttached) {
          _rootFocusNode.requestFocus();
        }
      });
    }
  }

  TuiVersionItem? _selectedVersion() {
    final items = widget.controller.versions?.items;
    if (items == null || items.isEmpty) return null;

    return items[widget.controller.selectedVersionIndex];
  }

  TuiReleaseItem? _selectedRelease() {
    final releases = widget.controller.releases;
    if (releases == null || releases.isEmpty) return null;

    return releases[widget.controller.selectedReleaseIndex];
  }

  Widget _unavailable(String message) =>
      Text(message, style: FvmTuiTextStyles.forTone(TuiTone.warning));

  Widget _content() => switch (widget.controller.route) {
    FvmTuiRoute.versions => VersionsScreen(
      controller: widget.controller,
      layoutMode: widget.layoutMode,
      onUse: _openUseVersion,
      onInstall: _openInstall,
    ),
    FvmTuiRoute.releases => ReleasesScreen(
      controller: widget.controller,
      layoutMode: widget.layoutMode,
      onInstall: _openInstall,
    ),
    FvmTuiRoute.useVersion => switch (_selectedVersion()) {
      final version? => UseVersionScreen(
        controller: widget.controller,
        version: version,
        onBack: () => _navigate(FvmTuiRoute.versions),
      ),
      null => _unavailable('Select an installed Flutter SDK first.'),
    },
    FvmTuiRoute.installOptions => switch (_installVersion) {
      final version? => InstallOptionsScreen(
        controller: widget.controller,
        version: version,
        onBack: () => _navigate(_installReturnRoute),
      ),
      null => _unavailable('Select a Flutter SDK to install first.'),
    },
    FvmTuiRoute.installProgress => InstallProgressScreen(
      controller: widget.controller,
    ),
    FvmTuiRoute.doctor => switch (widget.controller.doctor) {
      final report? => DoctorScreen(
        report: report,
        layoutMode: widget.layoutMode,
      ),
      null when widget.controller.loading => Text(
        'Running diagnostics…',
        style: FvmTuiTextStyles.muted,
      ),
      null => _unavailable('Diagnostics are not available.'),
    },
    FvmTuiRoute.configuration => switch (widget.controller.configuration) {
      final configuration? => ConfigurationScreen(
        key: ValueKey(configuration.scope),
        controller: widget.controller,
        onBack: () => _navigate(FvmTuiRoute.versions),
      ),
      null when widget.controller.loading => Text(
        'Loading configuration…',
        style: FvmTuiTextStyles.muted,
      ),
      null => _unavailable('Configuration is not available.'),
    },
  };

  void _navigate(FvmTuiRoute route) {
    if (!mounted) return;
    unawaited(widget.controller.goTo(route));
  }

  void _openUseVersion() {
    if (_selectedVersion() == null) return;
    _navigate(FvmTuiRoute.useVersion);
  }

  void _openInstall() {
    final route = widget.controller.route;
    final version = switch (route) {
      FvmTuiRoute.versions => _selectedVersion()?.id,
      FvmTuiRoute.releases => _selectedRelease()?.version,
      FvmTuiRoute.useVersion ||
      FvmTuiRoute.installOptions ||
      FvmTuiRoute.installProgress ||
      FvmTuiRoute.doctor ||
      FvmTuiRoute.configuration => null,
    };
    if (version == null) return;
    setState(() {
      _installVersion = version;
      _installReturnRoute = route;
    });
    _navigate(FvmTuiRoute.installOptions);
  }

  @override
  void didUpdateWidget(covariant FvmTuiApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _rootFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: {
      SingleActivator(LogicalKeyboardKey.keyQ, control: true): _QuitIntent(),
      SingleActivator(LogicalKeyboardKey.keyX, control: true): _QuitIntent(),
      if (widget.controller.route == FvmTuiRoute.installProgress)
        SingleActivator(LogicalKeyboardKey.keyC, control: true):
            _CancelInstallIntent(),
      SingleActivator(LogicalKeyboardKey.digit1): _NavigateIntent(
        FvmTuiRoute.versions,
      ),
      SingleActivator(LogicalKeyboardKey.digit2): _NavigateIntent(
        FvmTuiRoute.releases,
      ),
      SingleActivator(LogicalKeyboardKey.digit3): _NavigateIntent(
        FvmTuiRoute.doctor,
      ),
      SingleActivator(LogicalKeyboardKey.digit4): _NavigateIntent(
        FvmTuiRoute.configuration,
      ),
    },
    child: Actions(
      actions: {
        _QuitIntent: CallbackAction<_QuitIntent>((intent, context) {
          widget.onQuit();

          return KeyEventResult.handled;
        }),
        _CancelInstallIntent: CallbackAction<_CancelInstallIntent>((
          intent,
          context,
        ) {
          if (widget.controller.hasActiveInstall) {
            widget.controller.cancelInstall();
          } else {
            widget.onQuit();
          }

          return KeyEventResult.handled;
        }),
        _NavigateIntent: CallbackAction<_NavigateIntent>((intent, context) {
          _navigate(intent.route);

          return KeyEventResult.handled;
        }),
      },
      child: Focus(
        focusNode: _rootFocusNode,
        autofocus: true,
        child: ScreenShell(
          layoutMode: widget.layoutMode,
          route: widget.controller.route,
          content: _content(),
          onNavigate: _navigate,
          onBack: () => _navigate(FvmTuiRoute.versions),
        ),
      ),
    ),
  );
}

final class _QuitIntent extends Intent {
  const _QuitIntent();
}

final class _CancelInstallIntent extends Intent {
  const _CancelInstallIntent();
}

final class _NavigateIntent extends Intent {
  final FvmTuiRoute route;

  const _NavigateIntent(this.route);
}
