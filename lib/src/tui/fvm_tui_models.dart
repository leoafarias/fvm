enum FvmTuiRoute {
  versions,
  releases,
  useVersion,
  installOptions,
  installProgress,
  doctor,
  configuration,
}

enum FvmTuiLayoutMode { wide, compact }

enum TuiTone { neutral, info, success, warning, error }

enum OperationStatus { pending, active, complete, failed, cancelled }

typedef TuiVersionItem = ({
  String id,
  String version,
  String channel,
  String metadata,
  bool installed,
  bool isGlobal,
  bool isProject,
  bool needsSetup,
});

typedef TuiVersionsData = ({
  List<TuiVersionItem> items,
  String cachePath,
  int cacheBytes,
  String? updateMessage,
});

typedef TuiReleaseItem = ({
  String version,
  String channel,
  DateTime releaseDate,
  String? dartSdkVersion,
  String? architecture,
  bool activeChannel,
  bool installed,
});

typedef UseVersionRequest = ({
  String version,
  bool pin,
  bool runPubGet,
  bool updateVscode,
  bool updateMelos,
  bool force,
  String? flavor,
});

typedef InstallRequest = ({
  String version,
  bool useGitCache,
  bool runSetup,
  bool useAfterInstall,
  bool force,
});

enum InstallPhase {
  ensureCache,
  acquireLock,
  cloneSdk,
  validateRevision,
  setupFlutter,
  linkProject,
}

typedef InstallProgressUpdate = ({
  InstallPhase phase,
  OperationStatus status,
  String detail,
  int? exactPercent,
});

typedef DoctorCheck = ({String label, String value, TuiTone tone});
typedef DoctorSection = ({String name, TuiTone tone, List<DoctorCheck> checks});
typedef TuiDoctorReport = ({
  List<DoctorSection> sections,
  List<String> recommendations,
});

enum ConfigurationScope { global, project }

enum TuiConfigurationField {
  cachePath,
  gitCachePath,
  runPubGetOnSdkChanges,
  updateVscodeSettings,
  updateGitIgnore,
  updateMelosSettings,
  useGitCache,
  updateCheckEnabled,
}

typedef TuiConfiguration = ({
  ConfigurationScope scope,
  String cachePath,
  String gitCachePath,
  bool runPubGetOnSdkChanges,
  bool updateVscodeSettings,
  bool updateGitIgnore,
  bool updateMelosSettings,
  bool useGitCache,
  bool? updateCheckEnabled,
  Set<TuiConfigurationField> overriddenFields,
});

typedef TuiConfigurationPatch = ({
  ConfigurationScope scope,
  String? cachePath,
  String? gitCachePath,
  bool? runPubGetOnSdkChanges,
  bool? updateVscodeSettings,
  bool? updateGitIgnore,
  bool? updateMelosSettings,
  bool? useGitCache,
  bool? updateCheckEnabled,
});
