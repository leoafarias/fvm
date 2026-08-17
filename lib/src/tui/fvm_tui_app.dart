import 'dart:async';

import 'package:noir/noir.dart';

import 'fvm_tui_controller.dart';
import 'fvm_tui_models.dart';
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
  var _controllerRevision = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (mounted) setState(() => _controllerRevision += 1);
  }

  Widget _content() {
    if (widget.controller.loading) {
      return Text('Loading…', style: FvmTuiTextStyles.muted);
    }
    final error = widget.controller.error;
    if (error != null) {
      return Text(
        'Error: $error',
        style: FvmTuiTextStyles.forTone(TuiTone.error),
      );
    }

    final title = switch (widget.controller.route) {
      FvmTuiRoute.versions => 'Installed Flutter SDKs',
      FvmTuiRoute.releases => 'Flutter releases',
      FvmTuiRoute.useVersion => 'Use a Flutter version',
      FvmTuiRoute.installOptions => 'Install options',
      FvmTuiRoute.installProgress => 'Install progress',
      FvmTuiRoute.doctor => 'FVM Doctor',
      FvmTuiRoute.configuration => 'FVM Configuration',
    };

    return Text(title, style: FvmTuiTextStyles.heading);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.keyQ, control: true): _QuitIntent(),
    },
    child: Actions(
      actions: {
        _QuitIntent: CallbackAction<_QuitIntent>((intent, context) {
          widget.onQuit();

          return KeyEventResult.handled;
        }),
      },
      child: Focus(
        autofocus: true,
        child: ScreenShell(
          layoutMode: widget.layoutMode,
          route: widget.controller.route,
          content: _content(),
          onNavigate: (route) => unawaited(widget.controller.goTo(route)),
          onBack: () => unawaited(widget.controller.goTo(FvmTuiRoute.versions)),
        ),
      ),
    ),
  );
}

final class _QuitIntent extends Intent {
  const _QuitIntent();
}
