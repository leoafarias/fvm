import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';

import '../utils/exceptions.dart';
import '../utils/pretty_json.dart';

part 'project_registry_model.mapper.dart';

/// Writable schema version for the cache-local project registry.
const kProjectRegistrySchemaVersion = 1;

/// Status of a registered project when validated against the filesystem.
enum ProjectRegistryStatus { active, missing, unconfigured, invalid }

/// Persisted schema version 1 document stored at `projects.json`.
@MappableClass()
class ProjectRegistryDocument with ProjectRegistryDocumentMappable {
  final int schemaVersion;
  final List<ProjectRegistryEntry> projects;

  static final fromMap = ProjectRegistryDocumentMapper.fromMap;
  static final fromJson = ProjectRegistryDocumentMapper.fromJson;

  const ProjectRegistryDocument({
    required this.schemaVersion,
    required this.projects,
  });

  factory ProjectRegistryDocument.empty() {
    return const ProjectRegistryDocument(
      schemaVersion: kProjectRegistrySchemaVersion,
      projects: [],
    );
  }

  /// Parses schema version 1 JSON without silently repairing it.
  factory ProjectRegistryDocument.parse(
    String contents, {
    required String registryPath,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ProjectRegistryException(
          'Project registry at $registryPath is malformed: ${error.message}',
          registryPath: registryPath,
        ),
        stackTrace,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ProjectRegistryException(
        'Project registry at $registryPath is malformed: expected a JSON object.',
        registryPath: registryPath,
      );
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int) {
      throw ProjectRegistryException(
        'Project registry at $registryPath is missing a valid schemaVersion.',
        registryPath: registryPath,
      );
    }
    if (schemaVersion > kProjectRegistrySchemaVersion) {
      throw ProjectRegistryException(
        'Project registry at $registryPath uses schema version '
        '$schemaVersion, which this FVM version cannot write. '
        'Upgrade FVM or avoid registry commands until it is readable.',
        registryPath: registryPath,
      );
    }
    if (schemaVersion < 1) {
      throw ProjectRegistryException(
        'Project registry at $registryPath has invalid schema version '
        '$schemaVersion.',
        registryPath: registryPath,
      );
    }

    final projects = decoded['projects'];
    if (projects is! List) {
      throw ProjectRegistryException(
        'Project registry at $registryPath is missing a valid projects array.',
        registryPath: registryPath,
      );
    }

    final entries = <ProjectRegistryEntry>[];
    for (final item in projects) {
      if (item is! Map<String, dynamic>) {
        throw ProjectRegistryException(
          'Project registry at $registryPath contains an invalid project entry.',
          registryPath: registryPath,
        );
      }
      entries.add(ProjectRegistryEntry.parse(item, registryPath: registryPath));
    }

    return ProjectRegistryDocument(
      schemaVersion: schemaVersion,
      projects: entries,
    );
  }

  /// Deterministic JSON for atomic replacement.
  String toStorageJson() => prettyJson(toStorageMap());

  Map<String, dynamic> toStorageMap() {
    final sorted = [...projects]..sort((a, b) => a.path.compareTo(b.path));

    return {
      'schemaVersion': schemaVersion,
      'projects': [for (final project in sorted) project.toStorageMap()],
    };
  }
}

/// Last-known snapshot of a registered project.
@MappableClass()
class ProjectRegistryEntry with ProjectRegistryEntryMappable {
  final String path;
  final String name;
  final String? flutter;
  final Map<String, String> flavors;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  static final fromMap = ProjectRegistryEntryMapper.fromMap;
  static final fromJson = ProjectRegistryEntryMapper.fromJson;

  const ProjectRegistryEntry({
    required this.path,
    required this.name,
    required this.flutter,
    required this.flavors,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  factory ProjectRegistryEntry.parse(
    Map<String, dynamic> map, {
    required String registryPath,
  }) {
    final path = map['path'];
    final name = map['name'];
    final flavors = map['flavors'];
    final firstSeenAt = map['firstSeenAt'];
    final lastSeenAt = map['lastSeenAt'];
    final flutter = map['flutter'];

    if (path is! String || path.isEmpty) {
      throw ProjectRegistryException(
        'Project registry at $registryPath has an entry with an invalid path.',
        registryPath: registryPath,
      );
    }
    if (name is! String || name.isEmpty) {
      throw ProjectRegistryException(
        'Project registry at $registryPath has an entry with an invalid name.',
        registryPath: registryPath,
      );
    }
    if (flavors is! Map) {
      throw ProjectRegistryException(
        'Project registry at $registryPath has an entry with invalid flavors.',
        registryPath: registryPath,
      );
    }
    if (firstSeenAt is! String || lastSeenAt is! String) {
      throw ProjectRegistryException(
        'Project registry at $registryPath has an entry with invalid timestamps.',
        registryPath: registryPath,
      );
    }
    if (flutter != null && flutter is! String) {
      throw ProjectRegistryException(
        'Project registry at $registryPath has an entry with an invalid flutter value.',
        registryPath: registryPath,
      );
    }

    final parsedFlavors = <String, String>{};
    for (final entry in flavors.entries) {
      if (entry.value is! String) {
        throw ProjectRegistryException(
          'Project registry at $registryPath has an entry with invalid flavor values.',
          registryPath: registryPath,
        );
      }
      parsedFlavors[entry.key.toString()] = entry.value as String;
    }

    try {
      return ProjectRegistryEntry(
        path: path,
        name: name,
        flutter: flutter as String?,
        flavors: parsedFlavors,
        firstSeenAt: DateTime.parse(firstSeenAt).toUtc(),
        lastSeenAt: DateTime.parse(lastSeenAt).toUtc(),
      );
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ProjectRegistryException(
          'Project registry at $registryPath has an entry with invalid timestamps: '
          '${error.message}',
          registryPath: registryPath,
        ),
        stackTrace,
      );
    }
  }

  Map<String, dynamic> toStorageMap() {
    final flavorKeys = flavors.keys.toList()..sort();

    return {
      'path': path,
      'name': name,
      'flutter': flutter,
      'flavors': {for (final key in flavorKeys) key: flavors[key]},
      'firstSeenAt': firstSeenAt.toUtc().toIso8601String(),
      'lastSeenAt': lastSeenAt.toUtc().toIso8601String(),
    };
  }
}

/// Filesystem-validated view of a registry entry.
class RegisteredProject {
  final String path;
  final String name;
  final ProjectRegistryStatus status;
  final String? flutter;
  final Map<String, String> flavors;
  final List<String> referencedVersions;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final bool usesLastKnownSnapshot;

  const RegisteredProject({
    required this.path,
    required this.name,
    required this.status,
    required this.flutter,
    required this.flavors,
    required this.referencedVersions,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.usesLastKnownSnapshot,
  });

  bool get countsTowardUsage =>
      status == ProjectRegistryStatus.active ||
      status == ProjectRegistryStatus.invalid;
}

/// Usage of one installed cache version across known reachable projects.
class VersionUsage {
  final String version;
  final int projectCount;
  final List<String> projectPaths;
  final bool global;
  final bool unreferenced;

  const VersionUsage({
    required this.version,
    required this.projectCount,
    required this.projectPaths,
    required this.global,
    required this.unreferenced,
  });
}

/// Combined project validation and cache-usage snapshot.
class CacheUsageSnapshot {
  final List<RegisteredProject> projects;
  final List<VersionUsage> versionUsage;
  final List<String> unreferencedVersions;
  final List<String> missingVersions;

  const CacheUsageSnapshot({
    required this.projects,
    required this.versionUsage,
    required this.unreferencedVersions,
    required this.missingVersions,
  });
}
