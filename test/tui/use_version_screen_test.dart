import 'package:fvm/src/tui/fvm_tui_controller.dart';
import 'package:fvm/src/tui/screens/use_version_screen.dart';
import 'package:noir/noir.dart';
import 'package:test/test.dart';

import 'testing/fake_tui_ports.dart';

void main() {
  test('toggles exact options and applies through the controller', () async {
    final ports = FakeTuiPorts();
    final controller = FvmTuiController(dependencies: ports.dependencies);
    final key = GlobalKey<UseVersionScreenState>();
    final app = runTuiApp(
      UseVersionScreen(
        key: key,
        controller: controller,
        version: threeVersions.first,
        onBack: () {},
      ),
      width: 80,
      height: 24,
      headless: true,
    );

    key.currentState!.toggle(0);
    key.currentState!.toggle(2);
    await key.currentState!.apply();

    expect(ports.useRequests, hasLength(1));
    expect(ports.useRequests.single.pin, isTrue);
    expect(ports.useRequests.single.runPubGet, isTrue);
    expect(ports.useRequests.single.updateVscode, isFalse);
    expect(ports.useRequests.single.updateMelos, isTrue);

    app.dispose();
    controller.dispose();
  });
}
