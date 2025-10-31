import 'dart:convert';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'config_model.dart';
import 'flutter_version_model.dart';

part 'project_model.mapper.dart';

/// Represents a Flutter project.
///
/// This class provides methods and properties related to a Flutter project,
/// such as retrieving the project name, the active flavor, caching paths,
/// and pubspec-related operations.
@MappableClass(includeCustomMappers: [PubspecMapper()])
class Project with ProjectMappable {
  /// The directory path of the project.
  final String path;

  /// The configuration of the project, if available.
  final ProjectConfig? config;

  final Pubspec? pubspec;

  /// Creates a new instance of [Project].
  ///
  /// The [config] parameter represents the configuration of the project.
  /// The [path] parameter is the directory path of the project.
  /// The [pubspec] parameter represents the pubspec.yaml file of the project.
  const Project({
    required this.config,
    required this.path,
    required this.pubspec,
  });

  /// Loads the Flutter project from the given [path].
  ///
  /// The project is loaded by locating the FVM config file and the pubspec.yaml file.
  static Project loadFromDirectory(Directory directory) {
    final config = ProjectConfig.loadFromDirectory(directory);

    final pubspecFile = File(join(directory.path, 'pubspec.yaml'));
    final pubspec = pubspecFile.existsSync()
        ? Pubspec.parse(pubspecFile.readAsStringSync())
        : null;

    return Project(config: config, path: directory.path, pubspec: pubspec);
  }

  /// Retrieves the name of the project.
  @MappableField()
  String get name => pubspec?.name ?? basename(path);

  /// Retrieves the pinned Flutter SDK version within the project.
  ///
  /// Returns `null` if no version is pinned.
  @MappableField()
  FlutterVersion? get pinnedVersion {
    final sdkVersion = config?.flutter;

    return sdkVersion != null ? FlutterVersion.parse(sdkVersion) : null;
  }

  /// Retrieves the active configured flavor of the project.
  @MappableField()
  String? get activeFlavor {
    return flavors.keys.firstWhereOrNull(
      (key) => flavors[key] == pinnedVersion?.name,
    );
  }

  /// Retrieves the flavors defined in the project's `fvm.yaml` file.
  @MappableField()
  Map<String, String> get flavors => config?.flavors ?? {};

  /// Retrieves the dart tool package config.
  ///
  /// Returns `null` if the file doesn't exist.
  @MappableField()
  String? get dartToolGeneratorVersion => _dartToolGeneratorVersion(path);

  /// Retrieves the dart tool version from file.
  ///
  /// Returns `null` if the file doesn't exist.
  @MappableField()
  String? get dartToolVersion => _dartToolVersion(path);

  /// Indicates whether the project is a Flutter project.
  @MappableField()
  bool get isFlutter => pubspec?.dependencies.containsKey('flutter') ?? false;

  /// Retrieves the local FVM path of the project.
  ///
  /// This is the directory where FVM stores its configuration files.
  @MappableField()
  String get localFvmPath => _fvmPath(path);

  /// Retrieves the local FVM cache path of the project.
  ///
  /// This is the directory where Flutter SDK versions are cached.
  @MappableField()
  String get localVersionsCachePath {
    return join(_fvmPath(path), 'versions');
  }

  /// Returns the path of the Flutter SDK symlink within the project.
  @MappableField()
  String get localVersionSymlinkPath {
    return join(localVersionsCachePath, pinnedVersion?.name);
  }

  @MappableField()
  String get gitIgnorePath => join(path, '.gitignore');

  /// Indicates whether the project has `.gitignore` file.
  File get gitIgnoreFile => File(gitIgnorePath);

  /// Returns the path of the pubspec.yaml file.
  @MappableField()
  String get pubspecPath => join(path, 'pubspec.yaml');

  /// Returns the path of the FVM config file.
  @MappableField()
  String get configPath => _fvmConfigPath(path);

  /// Returns legacy path of the FVM config file.
  @MappableField()
  String get legacyConfigPath => _legacyFvmConfigPath(path);

  /// Indicates whether the project has an FVM config file.
  @MappableField()
  bool get hasConfig => config != null;

  /// Indicates whether the project has a pubspec.yaml file.
  @MappableField()
  bool get hasPubspec => pubspec != null;

  /// Retrieves the Flutter SDK constraint from the pubspec.yaml file.
  ///
  /// Returns `null` if the constraint is not defined.
  VersionConstraint? get sdkConstraint => pubspec?.environment?['sdk'];
}

String _fvmPath(String path) {
  return join(path, kFvmDirName);
}

String _legacyFvmConfigPath(String path) {
  return join(_fvmPath(path), kFvmLegacyConfigFileName);
}

String _fvmConfigPath(String path) {
  return join(path, kFvmConfigFileName);
}

String _dartToolPath(String projectPath) {
  return join(projectPath, '.dart_tool');
}

String? _dartToolGeneratorVersion(String projectPath) {
  final file = File(join(_dartToolPath(projectPath), 'package_config.json'));

  return file.existsSync()
      ? (jsonDecode(file.readAsStringSync())
          as Map<String, dynamic>)['generatorVersion'] as String?
      : null;
}

String? _dartToolVersion(String projectPath) {
  final file = File(join(_dartToolPath(projectPath), 'version'));

  return file.existsSync() ? file.readAsStringSync() : null;
}

class PubspecMapper extends SimpleMapper<Pubspec> {
  const PubspecMapper();

  /// Converts a Pubspec object to a JSON-compatible Map
  /// Only includes essential fields for serialization compatibility
  Map<String, dynamic> _pubspecToJsonMap(Pubspec pubspec) {
    final map = <String, dynamic>{'name': pubspec.name};

    // Core metadata
    if (pubspec.version != null) map['version'] = pubspec.version?.toString();
    if (pubspec.description != null) map['description'] = pubspec.description;

    // SDK and dependency constraints
    if (pubspec.environment != null && pubspec.environment!.isNotEmpty) {
      map['environment'] = pubspec.environment!.map(
        (key, value) => MapEntry(key, value?.toString()),
      );
    }

    // Dependencies
    if (pubspec.dependencies.isNotEmpty) {
      map['dependencies'] = _dependenciesToJsonMap(pubspec.dependencies);
    }
    if (pubspec.devDependencies.isNotEmpty) {
      map['dev_dependencies'] = _dependenciesToJsonMap(pubspec.devDependencies);
    }

    // Flutter configuration
    if (pubspec.flutter != null && pubspec.flutter!.isNotEmpty) {
      map['flutter'] = pubspec.flutter;
    }

    return map;
  }

  /// Converts dependency map to JSON-compatible format
  /// Handles all dependency types properly
  Map<String, dynamic> _dependenciesToJsonMap(
    Map<String, Dependency> dependencies,
  ) {
    return dependencies.map((key, value) {
      if (value is HostedDependency) {
        return MapEntry(key, value.version.toString());
      } else if (value is GitDependency) {
        final gitMap = <String, dynamic>{'url': value.url.toString()};
        if (value.ref != null) gitMap['ref'] = value.ref;
        if (value.path != null) gitMap['path'] = value.path;

        return MapEntry(key, {'git': gitMap});
      } else if (value is PathDependency) {
        return MapEntry(key, {'path': value.path});
      } else if (value is SdkDependency) {
        return MapEntry(key, {'sdk': value.sdk});
      }

      // Fallback for unknown dependency types
      return MapEntry(key, value.toString());
    });
  }

  @override
  // ignore: avoid-dynamic
  Pubspec decode(dynamic value) {
    return Pubspec.parse(value as String);
  }

  @override
  // ignore: avoid-dynamic
  dynamic encode(Pubspec self) {
    // Use Pubspec.fromJson() for round-trip compatibility
    // This leverages the package's built-in JSON deserialization
    final jsonMap = _pubspecToJsonMap(self);

    // Convert to JSON string for dart_mappable compatibility
    return jsonEncode(jsonMap);
  }
}
