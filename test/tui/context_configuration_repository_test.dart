import 'package:fvm/src/tui/adapters/context_configuration_repository.dart';
import 'package:fvm/src/tui/adapters/context_versions_repository.dart';
import 'package:fvm/src/tui/adapters/fvm_context_handle.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  test(
    'maps snapshots, reloads after save, and other adapters see context B',
    () async {
      final contextA = TestFactory.fastContext(debugLabel: 'config-a');
      final contextB = TestFactory.fastContext(debugLabel: 'config-b');
      var reloads = 0;
      final handle = FvmContextHandle(
        contextA,
        reload: (_) {
          reloads += 1;

          return contextB;
        },
      );
      final repository = ContextConfigurationRepository(handle);

      final before = await repository.load(ConfigurationScope.global);
      final saved = await repository.save((
        scope: ConfigurationScope.global,
        cachePath: null,
        gitCachePath: null,
        runPubGetOnSdkChanges: null,
        updateVscodeSettings: null,
        updateGitIgnore: null,
        updateMelosSettings: null,
        useGitCache: false,
        updateCheckEnabled: null,
      ));
      final versions = await ContextVersionsRepository(handle).load();

      expect(before.scope, ConfigurationScope.global);
      expect(saved.scope, ConfigurationScope.global);
      expect(reloads, 1);
      expect(handle.current, same(contextB));
      expect(versions.cachePath, contextB.versionsCachePath);
    },
  );
}
