import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

import '../utils/change_case.dart';
import '../utils/constants.dart';
import '../utils/pretty_json.dart';
import 'flutter_version_model.dart';

part 'config_model.mapper.dart';

@MappableEnum()
enum ConfigOptions {
  cachePath(description: 'Path where $kPackageName will cache versions'),
  useGitCache(
    description:
        'Enable/Disable git cache globally, which is used for faster version installs.',
  ),
  gitCachePath(description: 'Path where local Git reference cache is stored'),
  flutterUrl(description: 'Flutter repository Git URL to clone from'),
  disableUpdateCheck(
    description: 'Enable/Disable automatic update checking for FVM',
  );

  const ConfigOptions({required this.description});

  final String description;

  ChangeCase get _recase => ChangeCase(name);

  String get envKey => 'FVM_${_recase.constantCase}';

  String get paramKey => _recase.paramCase;

  String get propKey => _recase.camelCase;

  static ArgParser injectArgParser(ArgParser argParser) {
    final configKeysFunctions = {
      ConfigOptions.cachePath: () {
        argParser.addOption(
          ConfigOptions.cachePath.paramKey,
          help: ConfigOptions.cachePath.description,
        );
      },
      ConfigOptions.useGitCache: () {
        argParser.addFlag(
          ConfigOptions.useGitCache.paramKey,
          help: ConfigOptions.useGitCache.description,
          defaultsTo: true,
          negatable: true,
        );
      },
      ConfigOptions.gitCachePath: () {
        argParser.addOption(
          ConfigOptions.gitCachePath.paramKey,
          help: ConfigOptions.gitCachePath.description,
        );
      },
      ConfigOptions.flutterUrl: () {
        argParser.addOption(
          ConfigOptions.flutterUrl.paramKey,
          help: ConfigOptions.flutterUrl.description,
        );
      },
      ConfigOptions.disableUpdateCheck: () {
        argParser.addFlag(
          ConfigOptions.disableUpdateCheck.paramKey,
          help: ConfigOptions.disableUpdateCheck.description,
          defaultsTo: false,
          negatable: true,
        );
      },
    };

    for (final key in ConfigOptions.values) {
      configKeysFunctions[key]?.call();
    }

    return argParser;
  }
}

abstract class Config {
  // If should use gitCache
  final bool? useGitCache;

  final String? gitCachePath;

  /// Flutter repo url
  final String? flutterUrl;

  /// Directory where FVM is stored
  final String? cachePath;

  /// Constructor
  const Config({
    this.cachePath,
    this.useGitCache,
    this.gitCachePath,
    this.flutterUrl,
  });
}

abstract class FileConfig extends Config {
  final bool? privilegedAccess;
  final bool? runPubGetOnSdkChanges;
  final bool? updateVscodeSettings;
  final bool? updateGitIgnore;
  final bool? updateMelosSettings;

  /// Constructor
  const FileConfig({
    required super.cachePath,
    required super.useGitCache,
    required super.gitCachePath,
    required super.flutterUrl,
    required this.privilegedAccess,
    required this.runPubGetOnSdkChanges,
    required this.updateVscodeSettings,
    required this.updateGitIgnore,
    this.updateMelosSettings,
  });
}

@MappableClass(ignoreNull: true)
class EnvConfig extends Config with EnvConfigMappable {
  const EnvConfig({
    super.cachePath,
    super.useGitCache,
    super.gitCachePath,
    super.flutterUrl,
  });
}

@MappableClass(ignoreNull: true)
class AppConfig extends FileConfig with AppConfigMappable {
  final bool? disableUpdateCheck;

  final DateTime? lastUpdateCheck;

  final Set<FlutterFork> forks;
  const AppConfig({
    this.disableUpdateCheck,
    this.lastUpdateCheck,
    this.forks = const {},
    super.cachePath,
    super.useGitCache,
    super.gitCachePath,
    super.flutterUrl,
    super.privilegedAccess,
    super.runPubGetOnSdkChanges,
    super.updateVscodeSettings,
    super.updateGitIgnore,
    super.updateMelosSettings,
  });
}

@MappableClass(ignoreNull: true)
class LocalAppConfig with LocalAppConfigMappable implements AppConfig {
  /// Disables update notification
  @override
  bool? disableUpdateCheck;
  @override
  DateTime? lastUpdateCheck;
  @override
  late Set<FlutterFork> forks;

  @override
  String? cachePath;
  @override
  String? gitCachePath;
  @override
  String? flutterUrl;
  @override
  bool? useGitCache;
  @override
  bool? privilegedAccess;
  @override
  bool? runPubGetOnSdkChanges;
  @override
  bool? updateVscodeSettings;

  @override
  bool? updateGitIgnore;

  @override
  bool? updateMelosSettings;

  static final fromMap = LocalAppConfigMapper.fromMap;
  static final fromJson = LocalAppConfigMapper.fromJson;

  /// Constructor
  LocalAppConfig({
    this.disableUpdateCheck,
    this.lastUpdateCheck,
    this.cachePath,
    this.useGitCache,
    this.gitCachePath,
    this.flutterUrl,
    this.privilegedAccess,
    this.runPubGetOnSdkChanges,
    this.updateVscodeSettings,
    this.updateGitIgnore,
    this.updateMelosSettings,
    Set<FlutterFork>? forks,
  }) {
    this.forks = {...?forks};
  }

  static LocalAppConfig read() {
    try {
      return _configFile.existsSync()
          ? LocalAppConfig.fromJson(_configFile.readAsStringSync())
          : LocalAppConfig();
    } catch (e) {
      return LocalAppConfig();
    }
  }

  static File get _configFile => File(kAppConfigFile);

  bool get isEmpty => LocalAppConfig() == this;

  String get location => _configFile.path;

  void save() {
    // Ensure the parent directory exists before writing the file
    // This follows the same pattern used throughout FVM for directory creation
    final parentDir = _configFile.parent;
    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }
    _configFile.writeAsStringSync(prettyJson(toMap()));
  }
}

/// Project config
@MappableClass(ignoreNull: true)
class ProjectConfig extends FileConfig with ProjectConfigMappable {
  final String? flutter;
  final Map<String, String>? flavors;

  /// Constructor
  const ProjectConfig({
    this.flutter,
    this.flavors,
    super.cachePath,
    super.useGitCache,
    super.gitCachePath,
    super.flutterUrl,
    super.privilegedAccess,
    super.runPubGetOnSdkChanges,
    super.updateVscodeSettings,
    super.updateGitIgnore,
    super.updateMelosSettings,
  });

  static ProjectConfig? loadFromDirectory(Directory directory) {
    final configFile = File(p.join(directory.path, kFvmConfigFileName));

    return configFile.existsSync()
        ? ProjectConfig.fromJson(configFile.readAsStringSync())
        : null;
  }

  static ProjectConfig fromJson(String json) {
    return ProjectConfig.fromMap(jsonDecode(json));
  }

  static ProjectConfig fromMap(Map<String, dynamic> map) {
    return ProjectConfigMapper.fromMap({
      ...map,
      'flutter': map['flutterSdkVersion'] ?? map['flutter'],
    });
  }

  Map<String, dynamic> toLegacyMap() {
    return {
      if (flutter != null) 'flutterSdkVersion': flutter,
      if (flavors != null && flavors!.isNotEmpty) 'flavors': flavors,
    };
  }

  String toLegacyJson() => prettyJson(toLegacyMap());

  @override
  String toJson() => prettyJson(toMap());
}
