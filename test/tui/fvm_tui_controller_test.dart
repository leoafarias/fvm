import 'package:fvm/src/tui/fvm_tui_controller.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:test/test.dart';

import 'testing/fake_tui_ports.dart';

void main() {
  test('starts on versions and loads only the visible route', () async {
    final ports = FakeTuiPorts();
    final controller = FvmTuiController(dependencies: ports.dependencies);

    await controller.initialize();

    expect(controller.route, FvmTuiRoute.versions);
    expect(ports.versionsLoadCount, 1);
    expect(ports.releasesLoadCount, 0);
    controller.dispose();
  });

  test('selection is clamped when refreshed data becomes shorter', () async {
    final ports = FakeTuiPorts(versionBatches: [threeVersions, oneVersion]);
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.initialize();
    controller.selectVersion(2);

    await controller.refresh();

    expect(controller.selectedVersionIndex, 0);
    controller.dispose();
  });

  test('route data is loaded once until explicitly refreshed', () async {
    final ports = FakeTuiPorts();
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.initialize();

    await controller.goTo(FvmTuiRoute.releases);
    await controller.goTo(FvmTuiRoute.versions);
    await controller.goTo(FvmTuiRoute.releases);

    expect(ports.versionsLoadCount, 1);
    expect(ports.releasesLoadCount, 1);

    await controller.refresh();
    expect(ports.releasesLoadCount, 2);
    controller.dispose();
  });
}
