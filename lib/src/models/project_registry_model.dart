import 'dart:convert';

import '../utils/exceptions.dart';
import '../utils/pretty_json.dart';

/// Writable schema version for the cache-local project registry.
///
/// The registry stores project paths; pinned versions come from live configs.
const kProjectRegistrySchemaVersion = 1;

/// Reads the project roots out of registry JSON.
///
/// Throws [ProjectRegistryException] for formats this FVM cannot safely update.
List<String> parseProjectRegistry(
  String contents, {
  required String registryPath,
}) {
  Never invalid(String reason) {
    throw ProjectRegistryException('Project registry at $registryPath $reason');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(contents);
  } on FormatException catch (error) {
    invalid('is malformed: ${error.message}');
  }

  if (decoded is! Map<String, dynamic>) invalid('is not a JSON object.');

  final schemaVersion = decoded['schemaVersion'];
  if (schemaVersion is! int || schemaVersion < 1) {
    invalid('is missing a valid schemaVersion.');
  }
  if (schemaVersion > kProjectRegistrySchemaVersion) {
    invalid(
      'uses schema version $schemaVersion, which this FVM version cannot '
      'write. Upgrade FVM to use it again.',
    );
  }

  final projects = decoded['projects'];
  if (projects is! List) invalid('is missing a valid projects array.');

  final paths = <String>[];
  for (final item in projects) {
    if (item is! String || item.isEmpty) {
      invalid('contains an invalid project path.');
    }
    paths.add(item);
  }

  return paths;
}

/// Encodes [projects] deterministically, so rewriting an unchanged registry
/// produces identical bytes.
String encodeProjectRegistry(List<String> projects) {
  return prettyJson({
    'schemaVersion': kProjectRegistrySchemaVersion,
    'projects': [...projects]..sort(),
  });
}

/// Which Flutter SDK versions the projects FVM knows about are using.
///
/// Versions are keyed by their installed cache names. Project pins are
/// normalized through `CacheService.installedNameOf`, so a forked
/// channel-qualified pin still matches the directory stored in the cache.
class CacheProjectUsage {
  /// Known project roots that still resolve to a configured FVM project.
  final List<String> projectPaths;

  /// Project config locations that reference each installed version.
  final Map<String, List<ProjectVersionReference>> projectReferencesByVersion;

  /// The globally linked version, if one is set.
  final String? globalVersion;

  const CacheProjectUsage({
    required this.projectPaths,
    required this.projectReferencesByVersion,
    required this.globalVersion,
  });

  /// How many known projects pin [version], as their Flutter version or through
  /// a flavor. A project that pins the same SDK more than once still counts as
  /// one.
  int countFor(String version) {
    final references = projectReferencesByVersion[version];
    if (references == null || references.isEmpty) return 0;

    return {for (final reference in references) reference.projectPath}.length;
  }

  List<ProjectVersionReference> referencesFor(String version) =>
      projectReferencesByVersion[version] ?? const [];

  /// Whether nothing FVM knows about is using [version]. The globally linked
  /// SDK counts as in use even when no project pins it.
  bool isUnused(String version) =>
      version != globalVersion && countFor(version) == 0;
}

/// A primary or flavor pin in a known project config.
class ProjectVersionReference {
  final String projectPath;
  final String? flavor;

  const ProjectVersionReference({required this.projectPath, this.flavor});
}
