import 'package:fvm/src/tui/fvm_tui_controller.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:fvm/src/tui/screens/versions_screen.dart';
import 'package:noir/noir.dart';
import 'package:test/test.dart';

import 'testing/fake_tui_ports.dart';

void main() {
  test('ready screen mounts wide and follows controller selection', () async {
    final ports = FakeTuiPorts.withReadyData();
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.initialize();

    final app = runTuiApp(
      VersionsScreen(controller: controller, layoutMode: FvmTuiLayoutMode.wide),
      width: 110,
      height: 34,
      headless: true,
    );
    controller.selectVersion(2);

    expect(controller.selectedVersionIndex, 2);
    app.dispose();
    controller.dispose();
  });

  test('empty screen mounts compact', () async {
    final ports = FakeTuiPorts(versionBatches: [const []]);
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.initialize();

    final app = runTuiApp(
      VersionsScreen(
        controller: controller,
        layoutMode: FvmTuiLayoutMode.compact,
      ),
      width: 80,
      height: 24,
      headless: true,
    );

    app.dispose();
    controller.dispose();
  });

  test('error screen mounts compact', () async {
    final ports = FakeTuiPorts(versionsError: StateError('cache unavailable'));
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.initialize();

    final app = runTuiApp(
      VersionsScreen(
        controller: controller,
        layoutMode: FvmTuiLayoutMode.compact,
      ),
      width: 80,
      height: 24,
      headless: true,
    );

    expect(controller.error, isA<StateError>());
    app.dispose();
    controller.dispose();
  });
}
