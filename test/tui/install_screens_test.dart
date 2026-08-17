import 'package:fvm/src/tui/fvm_tui_controller.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:fvm/src/tui/screens/install_options_screen.dart';
import 'package:fvm/src/tui/screens/install_progress_screen.dart';
import 'package:noir/noir.dart';
import 'package:test/test.dart';

import 'testing/fake_tui_ports.dart';

void main() {
  test('install options toggle exact values and start installation', () async {
    final ports = FakeTuiPorts();
    final controller = FvmTuiController(dependencies: ports.dependencies);
    final key = GlobalKey<InstallOptionsScreenState>();
    final app = runTuiApp(
      InstallOptionsScreen(
        key: key,
        controller: controller,
        version: '3.35.1',
        onBack: () {},
      ),
      width: 80,
      height: 24,
      headless: true,
    );

    key.currentState!
      ..toggle(0)
      ..toggle(1)
      ..toggle(2)
      ..toggle(3);
    await key.currentState!.install();

    expect(ports.installRequests, [
      (
        version: '3.35.1',
        useGitCache: false,
        runSetup: false,
        useAfterInstall: true,
        force: true,
      ),
    ]);
    expect(controller.route, FvmTuiRoute.installProgress);

    app.dispose();
    controller.dispose();
  });

  test(
    'progress screen mounts and cancellation waits for runner cleanup',
    () async {
      final ports = FakeTuiPorts(blockInstall: true);
      final controller = FvmTuiController(dependencies: ports.dependencies);
      final running = controller.install((
        version: '3.35.1',
        useGitCache: true,
        runSetup: true,
        useAfterInstall: false,
        force: false,
      ));
      await ports.installStarted.future;
      final screen = InstallProgressScreen(controller: controller);
      final app = runTuiApp(screen, width: 80, height: 24, headless: true);

      screen.cancel();

      expect(ports.installCancelled, isTrue);
      expect(controller.hasActiveInstall, isTrue);
      ports.completeInstall();
      await running;
      expect(controller.hasActiveInstall, isFalse);

      app.dispose();
      controller.dispose();
    },
  );
}
