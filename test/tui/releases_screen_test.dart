import 'package:fvm/src/tui/fvm_tui_controller.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:fvm/src/tui/screens/releases_screen.dart';
import 'package:noir/noir.dart';
import 'package:test/test.dart';

import 'testing/fake_tui_ports.dart';

void main() {
  test('wide list mounts and selection changes detail data', () async {
    final ports = FakeTuiPorts(releaseItems: sampleReleases);
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.goTo(FvmTuiRoute.releases);

    final app = runTuiApp(
      ReleasesScreen(controller: controller, layoutMode: FvmTuiLayoutMode.wide),
      width: 110,
      height: 34,
      headless: true,
    );
    controller.selectRelease(1);

    expect(
      controller.releases![controller.selectedReleaseIndex].version,
      '3.35.0',
    );
    app.dispose();
    controller.dispose();
  });

  test('compact list and detail transitions are deterministic', () async {
    final ports = FakeTuiPorts(releaseItems: sampleReleases);
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.goTo(FvmTuiRoute.releases);
    final key = GlobalKey<ReleasesScreenState>();
    final app = runTuiApp(
      ReleasesScreen(
        key: key,
        controller: controller,
        layoutMode: FvmTuiLayoutMode.compact,
      ),
      width: 80,
      height: 24,
      headless: true,
    );

    expect(key.currentState!.showingDetail, isFalse);
    key.currentState!.showDetail();
    expect(key.currentState!.showingDetail, isTrue);
    key.currentState!.showList();
    expect(key.currentState!.showingDetail, isFalse);

    app.dispose();
    controller.dispose();
  });
}

final sampleReleases = <TuiReleaseItem>[
  (
    version: '3.36.0',
    channel: 'beta',
    releaseDate: DateTime.utc(2026, 8, 10),
    dartSdkVersion: '3.10.0',
    architecture: 'arm64',
    activeChannel: true,
    installed: false,
  ),
  (
    version: '3.35.0',
    channel: 'stable',
    releaseDate: DateTime.utc(2026, 8),
    dartSdkVersion: '3.9.0',
    architecture: 'arm64',
    activeChannel: false,
    installed: true,
  ),
];
