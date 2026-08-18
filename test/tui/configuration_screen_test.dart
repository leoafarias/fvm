import 'package:fvm/src/tui/fvm_tui_controller.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:fvm/src/tui/screens/configuration_screen.dart';
import 'package:noir/noir.dart';
import 'package:noir/noir_low_level.dart';
import 'package:test/test.dart';

import 'testing/fake_tui_ports.dart';

void main() {
  test('saves only dirty global fields', () async {
    final ports = FakeTuiPorts();
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.goTo(FvmTuiRoute.configuration);
    final key = GlobalKey<ConfigurationScreenState>();
    final app = runTuiApp(
      ConfigurationScreen(key: key, controller: controller, onBack: () {}),
      width: 90,
      height: 30,
      headless: true,
    );

    key.currentState!
      ..toggle(TuiConfigurationField.useGitCache)
      ..beginPathEdit(TuiConfigurationField.cachePath)
      ..setPathText(TuiConfigurationField.cachePath, '/new/cache')
      ..commitPathEdit();
    await key.currentState!.save();

    final patch = ports.configurationPatches.single;
    expect(patch.cachePath, '/new/cache');
    expect(patch.useGitCache, isFalse);
    expect(patch.gitCachePath, isNull);
    expect(patch.runPubGetOnSdkChanges, isNull);
    expect(patch.updateVscodeSettings, isNull);
    expect(patch.updateGitIgnore, isNull);
    expect(patch.updateMelosSettings, isNull);
    expect(patch.updateCheckEnabled, isNull);

    app.dispose();
    controller.dispose();
  });

  test(
    'project values show inheritance and update checking stays read-only',
    () async {
      final ports = FakeTuiPorts();
      final controller = FvmTuiController(dependencies: ports.dependencies);
      await controller.goTo(FvmTuiRoute.configuration);
      final key = GlobalKey<ConfigurationScreenState>();
      final app = runTuiApp(
        ConfigurationScreen(key: key, controller: controller, onBack: () {}),
        width: 72,
        height: 28,
        headless: true,
      );

      await key.currentState!.switchScope(ConfigurationScope.project);
      expect(
        key.currentState!.fieldLabel(TuiConfigurationField.useGitCache),
        contains('inherited'),
      );
      expect(
        key.currentState!.fieldLabel(TuiConfigurationField.updateCheckEnabled),
        contains('read-only'),
      );
      key.currentState!.toggle(TuiConfigurationField.updateCheckEnabled);
      await key.currentState!.save();

      expect(ports.configurationPatches.single.updateCheckEnabled, isNull);

      app.dispose();
      controller.dispose();
    },
  );

  test('left and right switch scope without saving configuration', () async {
    final input = InputManager();
    final ports = FakeTuiPorts();
    final controller = FvmTuiController(dependencies: ports.dependencies);
    await controller.goTo(FvmTuiRoute.configuration);
    final binding = TuiBinding(
      width: 90,
      height: 30,
      headless: true,
      inputManager: input,
    )..runApp(ConfigurationScreen(controller: controller, onBack: () {}));
    await Future<void>.delayed(Duration.zero);

    Future<void> pressAndWait(LogicalKeyboardKey key) async {
      input.dispatchKey(KeyEvent(logicalKey: key, keyCode: key.keyId));
      await Future<void>.delayed(Duration.zero);
      while (controller.loading) {
        await Future<void>.delayed(Duration.zero);
      }
      await Future<void>.delayed(Duration.zero);
    }

    await pressAndWait(LogicalKeyboardKey.arrowRight);
    expect(controller.configuration!.scope, ConfigurationScope.project);
    expect(ports.configurationPatches, isEmpty);

    await pressAndWait(LogicalKeyboardKey.arrowLeft);
    expect(controller.configuration!.scope, ConfigurationScope.global);
    expect(ports.configurationPatches, isEmpty);

    binding.dispose();
    controller.dispose();
  });
}
