import 'package:fvm/src/tui/fvm_tui_app.dart';
import 'package:fvm/src/tui/fvm_tui_controller.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:noir/noir.dart';
import 'package:noir/noir_low_level.dart';
import 'package:test/test.dart';

import 'testing/fake_tui_ports.dart';

void main() {
  test('FVM TUI shell mounts and disposes at the reference size', () {
    final ports = FakeTuiPorts.withReadyData();
    final controller = FvmTuiController(dependencies: ports.dependencies);
    final app = runTuiApp(
      FvmTuiApp(
        controller: controller,
        layoutMode: FvmTuiLayoutMode.wide,
        onQuit: () {},
      ),
      width: 110,
      height: 34,
      headless: true,
    );

    app.dispose();
    controller.dispose();
  });

  test('number shortcuts load and render each primary route', () async {
    final input = InputManager();
    final ports = FakeTuiPorts.withReadyData();
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.initialize();
    final binding =
        TuiBinding(width: 110, height: 34, headless: true, inputManager: input)
          ..runApp(
            FvmTuiApp(
              controller: controller,
              layoutMode: FvmTuiLayoutMode.wide,
              onQuit: () {},
            ),
          );
    await Future<void>.delayed(Duration.zero);

    for (final route in [
      (LogicalKeyboardKey.digit2, '2', FvmTuiRoute.releases),
      (LogicalKeyboardKey.digit3, '3', FvmTuiRoute.doctor),
      (LogicalKeyboardKey.digit4, '4', FvmTuiRoute.configuration),
      (LogicalKeyboardKey.digit1, '1', FvmTuiRoute.versions),
    ]) {
      input.dispatchKey(
        KeyEvent(logicalKey: route.$1, keyCode: 0, character: route.$2),
      );
      while (controller.loading) {
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.route, route.$3);
    }

    binding.dispose();
    controller.dispose();
  });
}
