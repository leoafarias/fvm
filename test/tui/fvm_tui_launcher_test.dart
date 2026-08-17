import 'dart:io';

import 'package:fvm/src/tui/fvm_tui_app.dart';
import 'package:fvm/src/tui/fvm_tui_controller.dart';
import 'package:fvm/src/tui/fvm_tui_launcher.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:io/io.dart';
import 'package:noir/noir.dart';
import 'package:noir/noir_low_level.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';
import 'testing/fake_tui_ports.dart';

void main() {
  test('selects layout from terminal width with an environment fallback', () {
    expect(
      initialLayoutMode(terminalColumns: () => 100),
      FvmTuiLayoutMode.wide,
    );
    expect(
      initialLayoutMode(terminalColumns: () => 99),
      FvmTuiLayoutMode.compact,
    );
    expect(
      initialLayoutMode(
        environment: const {'COLUMNS': '120'},
        terminalColumns: () => throw const StdoutException('not a terminal'),
      ),
      FvmTuiLayoutMode.wide,
    );
  });

  test('Ctrl+Q and Ctrl+X invoke the mounted app quit callback', () async {
    final input = InputManager();
    final ports = FakeTuiPorts.withReadyData();
    final controller = FvmTuiController(dependencies: ports.dependencies);
    var quits = 0;
    final binding =
        TuiBinding(width: 110, height: 34, headless: true, inputManager: input)
          ..runApp(
            FvmTuiApp(
              controller: controller,
              layoutMode: FvmTuiLayoutMode.wide,
              onQuit: () => quits += 1,
            ),
          );
    await Future<void>.delayed(Duration.zero);

    for (final key in [LogicalKeyboardKey.keyQ, LogicalKeyboardKey.keyX]) {
      input.dispatchKey(
        KeyEvent(
          logicalKey: key,
          keyCode: key.keyId,
          modifiers: KeyModifiers.ctrl,
        ),
      );
    }

    expect(quits, 2);
    binding.dispose();
    controller.dispose();
  });

  test('Ctrl+C cancels an active install before it can quit', () async {
    final input = InputManager();
    final ports = FakeTuiPorts(blockInstall: true);
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.initialize();
    var quits = 0;
    var fallbackEvents = 0;
    final fallback = input.onKey((event) {
      fallbackEvents += 1;
      event.consume();
    }, priority: InputPriority.widget);
    final binding =
        TuiBinding(width: 110, height: 34, headless: true, inputManager: input)
          ..runApp(
            FvmTuiApp(
              controller: controller,
              layoutMode: FvmTuiLayoutMode.wide,
              onQuit: () => quits += 1,
            ),
          );
    await Future<void>.delayed(Duration.zero);
    final running = controller.install((
      version: '3.35.1',
      useGitCache: true,
      runSetup: true,
      useAfterInstall: false,
      force: false,
    ));
    await ports.installStarted.future;
    await Future<void>.delayed(const Duration(milliseconds: 20));

    void pressCtrlC() => input.dispatchKey(
      KeyEvent(
        logicalKey: LogicalKeyboardKey.keyC,
        keyCode: LogicalKeyboardKey.keyC.keyId,
        modifiers: KeyModifiers.ctrl,
      ),
    );

    pressCtrlC();
    expect(ports.installCancelled, isTrue);
    expect(controller.hasActiveInstall, isTrue);
    expect(quits, 0);
    expect(fallbackEvents, 0);

    ports.completeInstall();
    await running;
    pressCtrlC();
    expect(quits, 1);
    expect(fallbackEvents, 0);

    fallback.cancel();
    binding.dispose();
    controller.dispose();
  });

  test('disposes the app once before disposing its controller', () async {
    final context = TestFactory.fastContext(stdinHasTerminal: true);
    final ports = FakeTuiPorts.withReadyData();
    late FvmTuiApp mountedWidget;
    var appDisposals = 0;
    final events = <String>[];
    final handle = _FakeAppHandle(
      onEnableMouse: () => events.add('mouse'),
      onDispose: () {
        appDisposals += 1;
        events.add('app');
        expect(
          () => mountedWidget.controller.addListener(() {}),
          returnsNormally,
        );
      },
    );

    final launch = launchFvmTui(
      context,
      dependencies: ports.dependencies,
      flushOutput: () async => events.add('flush'),
      mount: (widget) {
        mountedWidget = widget as FvmTuiApp;

        return handle;
      },
    );
    await Future<void>.delayed(Duration.zero);
    mountedWidget.onQuit();

    expect(await launch, ExitCode.success.code);
    expect(appDisposals, 1);
    expect(events, ['mouse', 'app', 'flush']);
    expect(() => mountedWidget.controller.addListener(() {}), throwsStateError);
  });
}

final class _FakeAppHandle implements FvmTuiAppHandle {
  _FakeAppHandle({required this.onEnableMouse, required this.onDispose});

  final void Function() onEnableMouse;
  final void Function() onDispose;

  @override
  void enableMouse() => onEnableMouse();

  @override
  void dispose() => onDispose();
}
