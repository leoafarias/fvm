import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/config_model.dart';
import '../models/flutter_version_model.dart';
import '../models/project_model.dart';
import '../models/project_registry_model.dart';
import '../utils/atomic_file.dart';
import '../utils/clock.dart';
import '../utils/exceptions.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'project_service.dart';

/// Owns project-registry persistence, identity, validation, and usage.
class ProjectRegistryService extends ContextualService {
  final Clock _clock;

  ProjectRegistryService(super.context, {Clock? clock})
      : _clock = clock ?? const Clock();

  bool _isLockContentionError(FileSystemException error) {
    if (error.osError?.errorCode == 32 || error.osError?.errorCode == 33) {
      return true;
    }

    final message = error.message.toLowerCase();

    return message.contains('lock failed') ||
        message.contains('resource temporarily unavailable') ||
        message.contains('operation would block') ||
        message.contains('already locked') ||
        message.contains('being used by another process');
  }

  Future<T> _withRegistryLock<T>(FutureOr<T> Function() action) async {
    final lockFile = File('$registryPath.lock');
    if (!lockFile.parent.existsSync()) {
      lockFile.parent.createSync(recursive: true);
    }

    RandomAccessFile? lockHandle;
    var lockAcquired = false;
    const retryDelay = Duration(milliseconds: 150);
    const waitLogThreshold = Duration(seconds: 2);
    const maxWait = Duration(minutes: 5);

    try {
      try {
        lockHandle = await lockFile.open(mode: FileMode.write);

        final lockWaitStart = DateTime.now();
        var waitingLogged = false;

        while (!lockAcquired) {
          try {
            await lockHandle.lock(FileLock.exclusive);
            lockAcquired = true;
          } on FileSystemException catch (error, stackTrace) {
            if (!_isLockContentionError(error)) {
              Error.throwWithStackTrace(
                ProjectRegistryException(
                  'Failed to acquire project registry lock at ${lockFile.path}: '
                  '${error.message}',
                  registryPath: registryPath,
                ),
                stackTrace,
              );
            }

            final elapsed = DateTime.now().difference(lockWaitStart);
            if (elapsed > maxWait) {
              Error.throwWithStackTrace(
                ProjectRegistryException(
                  'Timed out waiting for project registry lock at '
                  '${lockFile.path} after ${elapsed.inSeconds}s.',
                  registryPath: registryPath,
                ),
                stackTrace,
              );
            }

            if (!waitingLogged && elapsed >= waitLogThreshold) {
              waitingLogged = true;
              logger.debug(
                'Waiting for project registry lock at ${lockFile.path}...',
              );
            }

            await Future<void>.delayed(retryDelay);
          }
        }
      } on FileSystemException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          ProjectRegistryException(
            'Failed to acquire project registry lock at ${lockFile.path}: '
            '${error.message}',
            registryPath: registryPath,
          ),
          stackTrace,
        );
      }

      return await action();
    } finally {
      if (lockHandle != null) {
        if (lockAcquired) {
          try {
            await lockHandle.unlock();
          } on FileSystemException catch (error) {
            logger.warn(
              'Failed to unlock project registry lock at ${lockFile.path}: '
              '${error.message}',
            );
          }
        }
        try {
          await lockHandle.close();
        } on FileSystemException catch (error) {
          logger.warn(
            'Failed to close project registry lock at ${lockFile.path}: '
            '${error.message}',
          );
        }
      }
    }
  }

  String _absoluteNormalized(String input) {
    if (p.isAbsolute(input)) {
      return p.normalize(input);
    }

    return p.normalize(p.join(context.workingDirectory, input));
  }

  bool _pathsEqual(String left, String right) => p.equals(left, right);

  String? _tryParseNameWithAlias(String? identifier) {
    if (identifier == null || identifier.isEmpty) return null;

    try {
      return FlutterVersion.parse(identifier).nameWithAlias;
    } on FormatException {
      return null;
    }
  }

  Map<String, String> _normalizedFlavors(Map<String, String> flavors) {
    final normalized = <String, String>{};
    for (final entry in flavors.entries) {
      normalized[entry.key] =
          _tryParseNameWithAlias(entry.value) ?? entry.value;
    }

    return normalized;
  }

  List<String> _distinctReferences({
    required String? flutter,
    required Map<String, String> flavors,
  }) {
    final versions = <String>{};
    final primary = _tryParseNameWithAlias(flutter);
    if (primary != null) {
      versions.add(primary);
    }
    for (final value in flavors.values) {
      final parsed = _tryParseNameWithAlias(value);
      if (parsed != null) {
        versions.add(parsed);
      }
    }
    final sorted = versions.toList()..sort();

    return sorted;
  }

  ProjectRegistryDocument _readDocumentUnlocked() {
    final file = File(registryPath);
    if (!file.existsSync()) {
      return ProjectRegistryDocument.empty();
    }

    final String contents;
    try {
      contents = file.readAsStringSync();
    } on FileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ProjectRegistryException(
          'Unable to read project registry at $registryPath: ${error.message}',
          registryPath: registryPath,
        ),
        stackTrace,
      );
    }

    return ProjectRegistryDocument.parse(contents, registryPath: registryPath);
  }

  void _writeDocumentUnlocked(ProjectRegistryDocument document) {
    final file = File(registryPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    final contents = document.toStorageJson();
    final temp = File('${file.path}.$pid.tmp');
    temp.writeAsStringSync(contents);

    try {
      replaceFileAtomically(target: file, staged: temp);
    } on FileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ProjectRegistryException(
          'Unable to write project registry at $registryPath: ${error.message}',
          registryPath: registryPath,
        ),
        stackTrace,
      );
    }
  }

  ProjectRegistryEntry _entryFromProject(
    Project project, {
    required String canonicalPath,
    DateTime? firstSeenAt,
  }) {
    final now = _clock.now();

    return ProjectRegistryEntry(
      path: canonicalPath,
      name: project.name,
      flutter: _tryParseNameWithAlias(project.config?.flutter) ??
          project.config?.flutter,
      flavors: _normalizedFlavors(project.flavors),
      firstSeenAt: firstSeenAt ?? now,
      lastSeenAt: now,
    );
  }

  int _indexOfPath(List<ProjectRegistryEntry> projects, String path) {
    return projects.indexWhere((entry) => _pathsEqual(entry.path, path));
  }

  RegisteredProject _validateEntry(ProjectRegistryEntry entry) {
    final root = Directory(entry.path);
    if (!root.existsSync()) {
      return _viewFromSnapshot(entry, status: ProjectRegistryStatus.missing);
    }

    final ProjectConfig? config;
    try {
      config = ProjectConfig.loadFromDirectory(root);
    } on Exception {
      return _viewFromSnapshot(entry, status: ProjectRegistryStatus.invalid);
    }

    if (config == null) {
      return _viewFromSnapshot(
        entry,
        status: ProjectRegistryStatus.unconfigured,
      );
    }

    var name = p.basename(entry.path);
    try {
      name = Project.loadFromDirectory(root).name;
    } on Exception {
      // Keep the basename when pubspec cannot be read.
    }

    final flavors = config.flavors ?? {};
    final flutterValid = config.flutter == null ||
        _tryParseNameWithAlias(config.flutter) != null;
    final flavorsValid = flavors.values.every(
      (value) => _tryParseNameWithAlias(value) != null,
    );

    return RegisteredProject(
      path: entry.path,
      name: name,
      status: flutterValid && flavorsValid
          ? ProjectRegistryStatus.active
          : ProjectRegistryStatus.invalid,
      flutter: config.flutter,
      flavors: flavors,
      referencedVersions: _distinctReferences(
        flutter: config.flutter,
        flavors: flavors,
      ),
      firstSeenAt: entry.firstSeenAt,
      lastSeenAt: entry.lastSeenAt,
      usesLastKnownSnapshot: false,
    );
  }

  RegisteredProject _viewFromSnapshot(
    ProjectRegistryEntry entry, {
    required ProjectRegistryStatus status,
  }) {
    return RegisteredProject(
      path: entry.path,
      name: entry.name,
      status: status,
      flutter: entry.flutter,
      flavors: entry.flavors,
      referencedVersions: _distinctReferences(
        flutter: entry.flutter,
        flavors: entry.flavors,
      ),
      firstSeenAt: entry.firstSeenAt,
      lastSeenAt: entry.lastSeenAt,
      usesLastKnownSnapshot: true,
    );
  }

  List<RegisteredProject> _validateDocument(ProjectRegistryDocument document) {
    return [for (final entry in document.projects) _validateEntry(entry)];
  }

  int _compareRegisteredProjects(RegisteredProject a, RegisteredProject b) {
    final aActive = a.status == ProjectRegistryStatus.active;
    final bActive = b.status == ProjectRegistryStatus.active;
    if (aActive != bActive) {
      return aActive ? -1 : 1;
    }
    if (aActive) {
      final bySeen = b.lastSeenAt.compareTo(a.lastSeenAt);
      if (bySeen != 0) return bySeen;

      return a.path.compareTo(b.path);
    }

    final byStatus = a.status.name.compareTo(b.status.name);
    if (byStatus != 0) return byStatus;

    return a.path.compareTo(b.path);
  }

  CacheUsageSnapshot _buildUsage({
    required List<RegisteredProject> projects,
    required List<String> installedVersions,
    required String? globalVersion,
    Project? includeTransient,
    bool registryReadable = true,
  }) {
    final references = <String, Set<String>>{};
    final missing = <String>{};

    void addReference(String version, String projectPath) {
      references.putIfAbsent(version, () => {}).add(projectPath);
    }

    for (final project in projects) {
      if (!project.countsTowardUsage) continue;
      for (final version in project.referencedVersions) {
        addReference(version, project.path);
        if (!installedVersions.contains(version) &&
            project.status == ProjectRegistryStatus.active) {
          missing.add(version);
        }
      }
    }

    if (includeTransient != null && includeTransient.hasConfig) {
      final transientPath = canonicalizeProjectPath(includeTransient.path);
      final alreadyCounted = projects.any(
        (project) =>
            project.countsTowardUsage && _pathsEqual(project.path, transientPath),
      );
      if (!alreadyCounted) {
        for (final version in _distinctReferences(
          flutter: includeTransient.config?.flutter,
          flavors: includeTransient.flavors,
        )) {
          addReference(version, transientPath);
          if (!installedVersions.contains(version)) {
            missing.add(version);
          }
        }
      }
    }

    final versionUsage = [
      for (final version in installedVersions)
        VersionUsage(
          version: version,
          projectCount: references[version]?.length ?? 0,
          projectPaths: (references[version]?.toList() ?? [])..sort(),
          global: globalVersion != null && globalVersion == version,
          unreferenced: registryReadable &&
              (references[version]?.isEmpty ?? true) &&
              globalVersion != version,
        ),
    ];
    final unreferenced = [
      for (final usage in versionUsage)
        if (usage.unreferenced) usage.version,
    ]..sort();
    final missingVersions = missing.toList()..sort();
    final sortedProjects = [...projects]..sort(_compareRegisteredProjects);

    return CacheUsageSnapshot(
      projects: sortedProjects,
      versionUsage: versionUsage,
      unreferencedVersions: unreferenced,
      missingVersions: missingVersions,
    );
  }

  String get registryPath => context.projectsRegistryPath;

  /// Canonical absolute identity for an existing or missing project root.
  String canonicalizeProjectPath(String input) {
    final normalized = _absoluteNormalized(input);
    try {
      if (Directory(normalized).existsSync()) {
        return Directory(normalized).resolveSymbolicLinksSync();
      }
    } on FileSystemException {
      return normalized;
    }

    return normalized;
  }

  /// Secondary automatic tracking. Never fails the parent command.
  Future<void> trackAutomatically(Project project) async {
    if (context.isCI) {
      logger.debug('Skipping project registry tracking in CI');

      return;
    }

    try {
      await upsert(project);
    } on Exception catch (error, stackTrace) {
      logger.warn(
        'Failed to update project registry at $registryPath: $error',
      );
      logger.logTrace(stackTrace);
    }
  }

  /// Adds or refreshes a project snapshot. Throws on registry I/O errors.
  Future<void> upsert(Project project) async {
    final canonicalPath = canonicalizeProjectPath(project.path);

    await _withRegistryLock(() {
      final document = _readDocumentUnlocked();
      final projects = [...document.projects];
      final index = _indexOfPath(projects, canonicalPath);
      if (index == -1) {
        projects.add(
          _entryFromProject(project, canonicalPath: canonicalPath),
        );
      } else {
        projects[index] = _entryFromProject(
          project,
          canonicalPath: canonicalPath,
          firstSeenAt: projects[index].firstSeenAt,
        );
      }

      _writeDocumentUnlocked(
        ProjectRegistryDocument(
          schemaVersion: kProjectRegistrySchemaVersion,
          projects: projects,
        ),
      );
    });
  }

  /// Resolves the nearest configured ancestor and upserts it.
  Future<Project> addFromPath(String? path) async {
    final directory = Directory(
      path == null || path.isEmpty
          ? context.workingDirectory
          : _absoluteNormalized(path),
    );
    final project = get<ProjectService>().findAncestor(directory: directory);
    if (!project.hasConfig) {
      throw AppException(
        'No FVM configuration found for ${directory.path}. '
        'Projects are recorded only after fvm use, a project-aware '
        'fvm install, or when an existing .fvmrc / legacy config can be read.',
      );
    }

    await upsert(project);

    return project;
  }

  /// Removes the matching registry entry. Returns whether an entry was removed.
  Future<bool> removePath(String input) {
    final normalized = canonicalizeProjectPath(input);

    return _withRegistryLock(() {
      final document = _readDocumentUnlocked();
      final projects = [...document.projects];
      final index = _indexOfPath(projects, normalized);
      if (index == -1) {
        return false;
      }

      projects.removeAt(index);
      _writeDocumentUnlocked(
        ProjectRegistryDocument(
          schemaVersion: kProjectRegistrySchemaVersion,
          projects: projects,
        ),
      );

      return true;
    });
  }

  /// Removes currently missing or unconfigured entries. Returns the count.
  Future<int> pruneStaleEntries() {
    return _withRegistryLock(() {
      final document = _readDocumentUnlocked();
      final validated = _validateDocument(document);
      final stalePaths = {
        for (final project in validated)
          if (project.status == ProjectRegistryStatus.missing ||
              project.status == ProjectRegistryStatus.unconfigured)
            project.path,
      };
      if (stalePaths.isEmpty) {
        return 0;
      }

      final remaining = [
        for (final entry in document.projects)
          if (!stalePaths.contains(entry.path)) entry,
      ];
      _writeDocumentUnlocked(
        ProjectRegistryDocument(
          schemaVersion: kProjectRegistrySchemaVersion,
          projects: remaining,
        ),
      );

      return stalePaths.length;
    });
  }

  /// Loads the persisted document. Absence is an empty registry.
  Future<ProjectRegistryDocument> loadDocument() {
    return _withRegistryLock(_readDocumentUnlocked);
  }

  /// Validates each entry against the filesystem without mutating the registry.
  Future<List<RegisteredProject>> listProjects() async {
    final document = await loadDocument();
    final projects = _validateDocument(document)..sort(_compareRegisteredProjects);

    return projects;
  }

  /// Calculates installed-version usage for known reachable projects.
  Future<CacheUsageSnapshot> calculateUsage({
    Project? includeTransient,
    bool ignoreRegistryErrors = false,
  }) async {
    final installed = await get<CacheService>().getAllVersions();
    final installedNames = [
      for (final version in installed) version.nameWithAlias,
    ];
    List<RegisteredProject> projects;
    var registryReadable = true;
    try {
      projects = await listProjects();
    } on ProjectRegistryException catch (error, stackTrace) {
      if (!ignoreRegistryErrors) {
        rethrow;
      }
      logger.warn(
        'Failed to read project registry at ${error.registryPath}: $error',
      );
      logger.logTrace(stackTrace);
      projects = [];
      registryReadable = false;
    }
    final globalVersion = get<CacheService>().getGlobalVersion();

    return _buildUsage(
      projects: projects,
      installedVersions: installedNames,
      globalVersion: globalVersion,
      includeTransient: includeTransient,
      registryReadable: registryReadable,
    );
  }
}
