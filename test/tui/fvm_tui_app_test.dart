import 'package:fvm/src/tui/fvm_tui_app.dart';
import 'package:fvm/src/tui/fvm_tui_controller.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:noir/noir.dart';
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
}
