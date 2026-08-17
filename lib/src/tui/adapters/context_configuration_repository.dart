import '../../services/configuration_service.dart';
import '../fvm_tui_models.dart';
import '../fvm_tui_ports.dart';
import 'fvm_context_handle.dart';

final class ContextConfigurationRepository implements ConfigurationRepository {
  final FvmContextHandle contextHandle;

  const ContextConfigurationRepository(this.contextHandle);

  ConfigurationTarget _target(ConfigurationScope scope) => switch (scope) {
    ConfigurationScope.global => ConfigurationTarget.global,
    ConfigurationScope.project => ConfigurationTarget.project,
  };

  ConfigurationScope _scope(ConfigurationTarget target) => switch (target) {
    ConfigurationTarget.global => ConfigurationScope.global,
    ConfigurationTarget.project => ConfigurationScope.project,
  };

  TuiConfigurationField _field(ConfigurationSetting setting) =>
      switch (setting) {
        ConfigurationSetting.cachePath => TuiConfigurationField.cachePath,
        ConfigurationSetting.gitCachePath => TuiConfigurationField.gitCachePath,
        ConfigurationSetting.runPubGetOnSdkChanges =>
          TuiConfigurationField.runPubGetOnSdkChanges,
        ConfigurationSetting.updateVscodeSettings =>
          TuiConfigurationField.updateVscodeSettings,
        ConfigurationSetting.updateGitIgnore =>
          TuiConfigurationField.updateGitIgnore,
        ConfigurationSetting.updateMelosSettings =>
          TuiConfigurationField.updateMelosSettings,
        ConfigurationSetting.useGitCache => TuiConfigurationField.useGitCache,
        ConfigurationSetting.updateCheckEnabled =>
          TuiConfigurationField.updateCheckEnabled,
      };

  TuiConfiguration _configuration(ConfigurationSnapshot snapshot) => (
    scope: _scope(snapshot.target),
    cachePath: snapshot.cachePath,
    gitCachePath: snapshot.gitCachePath,
    runPubGetOnSdkChanges: snapshot.runPubGetOnSdkChanges,
    updateVscodeSettings: snapshot.updateVscodeSettings,
    updateGitIgnore: snapshot.updateGitIgnore,
    updateMelosSettings: snapshot.updateMelosSettings,
    useGitCache: snapshot.useGitCache,
    updateCheckEnabled: snapshot.updateCheckEnabled,
    overriddenFields: snapshot.overriddenSettings.map(_field).toSet(),
  );

  @override
  Future<TuiConfiguration> load(ConfigurationScope scope) async {
    final context = contextHandle.current;
    final snapshot = context.get<ConfigurationService>().read(_target(scope));

    return _configuration(snapshot);
  }

  @override
  Future<TuiConfiguration> save(TuiConfigurationPatch patch) async {
    final sourceContext = contextHandle.current;
    sourceContext.get<ConfigurationService>().save(_target(patch.scope), (
      cachePath: patch.cachePath,
      gitCachePath: patch.gitCachePath,
      flutterUrl: null,
      runPubGetOnSdkChanges: patch.runPubGetOnSdkChanges,
      updateVscodeSettings: patch.updateVscodeSettings,
      updateGitIgnore: patch.updateGitIgnore,
      updateMelosSettings: patch.updateMelosSettings,
      useGitCache: patch.useGitCache,
      updateCheckEnabled: patch.updateCheckEnabled,
    ));
    contextHandle.reloadFromDisk();
    final refreshed = contextHandle.current.get<ConfigurationService>().read(
      _target(patch.scope),
    );

    return _configuration(refreshed);
  }
}
