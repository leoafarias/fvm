import 'dart:async';
import 'dart:io';

import 'package:noir/noir.dart';

import '../utils/context.dart';
import 'fvm_tui_app.dart';
import 'fvm_tui_controller.dart';
import 'fvm_tui_dependencies.dart';
import 'fvm_tui_models.dart';

abstract interface class FvmTuiAppHandle implements Disposable {
  void enableMouse();
}

typedef FvmTuiMount = FvmTuiAppHandle Function(Widget widget);
typedef FvmTuiFlushOutput = Future<void> Function();

final class _NoirFvmTuiAppHandle implements FvmTuiAppHandle {
  final TuiApp app;

  const _NoirFvmTuiAppHandle(this.app);

  @override
  void enableMouse() => app.enableMouse();

  @override
  void dispose() => app.dispose();
}

FvmTuiAppHandle mountFvmTuiApp(Widget widget) =>
    _NoirFvmTuiAppHandle(runTuiApp(widget));

Future<void> flushFvmTuiOutput() async {
  // Noir's synchronous disposal starts one final asynchronous sink flush.
  // Yield once so that flush can release stdout before we request our drain.
  await Future<void>.delayed(Duration.zero);
  await stdout.flush();
}

int _readTerminalColumns(
  Map<String, String>? environment,
  int Function()? terminalColumns,
) {
  try {
    return (terminalColumns ?? () => stdout.terminalColumns)();
  } on StdoutException {
    return int.tryParse(
          (environment ?? Platform.environment)['COLUMNS'] ?? '',
        ) ??
        80;
  }
}

/// Chooses the layout once at launch. Noir does not yet expose a public,
/// reactive terminal-resize signal for switching layout thresholds at runtime.
FvmTuiLayoutMode initialLayoutMode({
  Map<String, String>? environment,
  int Function()? terminalColumns,
}) {
  final columns = _readTerminalColumns(environment, terminalColumns);

  return columns >= 100 ? FvmTuiLayoutMode.wide : FvmTuiLayoutMode.compact;
}

Future<int> launchFvmTui(
  FvmContext context, {
  FvmTuiDependencies? dependencies,
  FvmTuiMount mount = mountFvmTuiApp,
  FvmTuiFlushOutput flushOutput = flushFvmTuiOutput,
}) async {
  final done = Completer<int>();
  final controller = FvmTuiController(
    dependencies: dependencies ?? createFvmTuiDependencies(context),
  );
  FvmTuiAppHandle? app;

  void finish([int code = 0]) {
    if (!done.isCompleted) done.complete(code);
  }

  try {
    app = mount(
      FvmTuiApp(
        controller: controller,
        layoutMode: initialLayoutMode(environment: context.environment),
        onQuit: finish,
      ),
    );
    app.enableMouse();
    unawaited(controller.initialize());

    return await done.future;
  } finally {
    try {
      app?.dispose();
      // Noir flushes renderer writes asynchronously. Drain the sink before
      // bin/main.dart closes it, otherwise graceful quit can race that close.
      await flushOutput();
    } finally {
      controller.dispose();
    }
  }
}
