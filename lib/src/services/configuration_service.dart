import 'dart:convert';
import 'dart:io';

import '../models/config_model.dart';
import '../models/project_model.dart';
import '../utils/exceptions.dart';
import 'base_service.dart';
import 'project_service.dart';

enum ConfigurationTarget { global, project }

enum ConfigurationSetting {
  cachePath,
  gitCachePath,
  runPubGetOnSdkChanges,
  updateVscodeSettings,
  updateGitIgnore,
  updateMelosSettings,
  useGitCache,
  updateCheckEnabled,
}

typedef ConfigurationSnapshot = ({
  ConfigurationTarget target,
  String cachePath,
  String gitCachePath,
  bool runPubGetOnSdkChanges,
  bool updateVscodeSettings,
  bool updateGitIgnore,
  bool updateMelosSettings,
  bool useGitCache,
  bool? updateCheckEnabled,
  Set<ConfigurationSetting> overriddenSettings,
});

typedef ConfigurationPatch = ({
  String? cachePath,
  String? gitCachePath,
  String? flutterUrl,
  bool? runPubGetOnSdkChanges,
  bool? updateVscodeSettings,
  bool? updateGitIgnore,
  bool? updateMelosSettings,
  bool? useGitCache,
  bool? updateCheckEnabled,
});

final class ConfigurationService extends ContextualService {
  const ConfigurationService(super.context);

  void _validate(ConfigurationPatch patch) {
    for (final entry in {
      'cache path': patch.cachePath,
      'Git cache path': patch.gitCachePath,
      'Flutter URL': patch.flutterUrl,
    }.entries) {
      if (entry.value != null && entry.value!.trim().isEmpty) {
        throw AppException('${entry.key} cannot be empty.');
      }
    }
  }

  ConfigurationSnapshot _globalSnapshot(LocalAppConfig config) => (
    target: ConfigurationTarget.global,
    cachePath: config.cachePath ?? context.fvmDir,
    gitCachePath: config.gitCachePath ?? context.gitCachePath,
    runPubGetOnSdkChanges:
        config.runPubGetOnSdkChanges ?? context.runPubGetOnSdkChanges,
    updateVscodeSettings:
        config.updateVscodeSettings ??
        context.config.updateVscodeSettings ??
        true,
    updateGitIgnore:
        config.updateGitIgnore ?? context.config.updateGitIgnore ?? true,
    updateMelosSettings:
        config.updateMelosSettings ??
        context.config.updateMelosSettings ??
        true,
    useGitCache: config.useGitCache ?? context.gitCache,
    updateCheckEnabled:
        !(config.disableUpdateCheck ?? context.updateCheckDisabled),
    overriddenSettings: _globalOverrides(config),
  );

  Set<ConfigurationSetting> _globalOverrides(LocalAppConfig config) => {
    if (config.cachePath != null) ConfigurationSetting.cachePath,
    if (config.gitCachePath != null) ConfigurationSetting.gitCachePath,
    if (config.runPubGetOnSdkChanges != null)
      ConfigurationSetting.runPubGetOnSdkChanges,
    if (config.updateVscodeSettings != null)
      ConfigurationSetting.updateVscodeSettings,
    if (config.updateGitIgnore != null) ConfigurationSetting.updateGitIgnore,
    if (config.updateMelosSettings != null)
      ConfigurationSetting.updateMelosSettings,
    if (config.useGitCache != null) ConfigurationSetting.useGitCache,
    if (config.disableUpdateCheck != null)
      ConfigurationSetting.updateCheckEnabled,
  };

  ConfigurationSnapshot _projectSnapshot(Project project) {
    final config = project.config ?? const ProjectConfig();

    return (
      target: ConfigurationTarget.project,
      cachePath: config.cachePath ?? context.fvmDir,
      gitCachePath: config.gitCachePath ?? context.gitCachePath,
      runPubGetOnSdkChanges:
          config.runPubGetOnSdkChanges ?? context.runPubGetOnSdkChanges,
      updateVscodeSettings:
          config.updateVscodeSettings ??
          context.config.updateVscodeSettings ??
          true,
      updateGitIgnore:
          config.updateGitIgnore ?? context.config.updateGitIgnore ?? true,
      updateMelosSettings:
          config.updateMelosSettings ??
          context.config.updateMelosSettings ??
          true,
      useGitCache: config.useGitCache ?? context.gitCache,
      updateCheckEnabled: null,
      overriddenSettings: _projectOverrides(project),
    );
  }

  Set<ConfigurationSetting> _projectOverrides(Project project) {
    final file = File(project.configPath);
    if (!file.existsSync()) return {};
    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } catch (_, stackTrace) {
      Error.throwWithStackTrace(
        AppException(
          'FVM project configuration file is invalid: "${file.path}". '
          'Fix it before changing settings.',
        ),
        stackTrace,
      );
    }
    if (decoded is! Map) {
      throw AppException(
        'FVM project configuration file is invalid: "${file.path}". '
        'Fix it before changing settings.',
      );
    }
    final keys = decoded.keys.map((key) => key.toString()).toSet();

    return {
      if (keys.contains('cachePath')) ConfigurationSetting.cachePath,
      if (keys.contains('gitCachePath')) ConfigurationSetting.gitCachePath,
      if (keys.contains('runPubGetOnSdkChanges'))
        ConfigurationSetting.runPubGetOnSdkChanges,
      if (keys.contains('updateVscodeSettings'))
        ConfigurationSetting.updateVscodeSettings,
      if (keys.contains('updateGitIgnore'))
        ConfigurationSetting.updateGitIgnore,
      if (keys.contains('updateMelosSettings'))
        ConfigurationSetting.updateMelosSettings,
      if (keys.contains('useGitCache')) ConfigurationSetting.useGitCache,
    };
  }

  Project _readProject() {
    try {
      return get<ProjectService>().findAncestor();
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const AppException(
          'FVM project configuration file is invalid. '
          'Fix it before changing settings.',
        ),
        stackTrace,
      );
    }
  }

  ConfigurationSnapshot _saveGlobal(ConfigurationPatch patch) {
    final config = LocalAppConfig.read(
      path: context.appConfigPath,
      requireValid: true,
    );
    if (patch.cachePath case final value?) config.cachePath = value;
    if (patch.gitCachePath case final value?) config.gitCachePath = value;
    if (patch.flutterUrl case final value?) config.flutterUrl = value;
    if (patch.runPubGetOnSdkChanges case final value?) {
      config.runPubGetOnSdkChanges = value;
    }
    if (patch.updateVscodeSettings case final value?) {
      config.updateVscodeSettings = value;
    }
    if (patch.updateGitIgnore case final value?) {
      config.updateGitIgnore = value;
    }
    if (patch.updateMelosSettings case final value?) {
      config.updateMelosSettings = value;
    }
    if (patch.useGitCache case final value?) config.useGitCache = value;
    if (patch.updateCheckEnabled case final value?) {
      config.disableUpdateCheck = !value;
    }
    config.save(path: context.appConfigPath);

    return _globalSnapshot(
      LocalAppConfig.read(path: context.appConfigPath, requireValid: true),
    );
  }

  ConfigurationSnapshot _saveProject(ConfigurationPatch patch) {
    if (patch.updateCheckEnabled != null) {
      throw const AppException(
        'Update checking is global-only and cannot be saved in .fvmrc.',
      );
    }
    if (patch.flutterUrl != null) {
      throw const AppException(
        'Flutter URL is not editable from the project configuration screen.',
      );
    }
    final project = _readProject();
    _projectOverrides(project);
    final updated = get<ProjectService>().update(
      project,
      cachePath: patch.cachePath,
      gitCachePath: patch.gitCachePath,
      runPubGetOnSdkChanges: patch.runPubGetOnSdkChanges,
      updateVscodeSettings: patch.updateVscodeSettings,
      updateGitIgnore: patch.updateGitIgnore,
      updateMelosSettings: patch.updateMelosSettings,
      useGitCache: patch.useGitCache,
    );

    return _projectSnapshot(Project.loadFromDirectory(Directory(updated.path)));
  }

  ConfigurationSnapshot read(ConfigurationTarget target) => switch (target) {
    ConfigurationTarget.global => _globalSnapshot(
      LocalAppConfig.read(path: context.appConfigPath, requireValid: true),
    ),
    ConfigurationTarget.project => _projectSnapshot(_readProject()),
  };

  ConfigurationSnapshot save(
    ConfigurationTarget target,
    ConfigurationPatch patch,
  ) {
    _validate(patch);

    return switch (target) {
      ConfigurationTarget.global => _saveGlobal(patch),
      ConfigurationTarget.project => _saveProject(patch),
    };
  }
}
