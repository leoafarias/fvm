import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/config_model.dart';
import '../models/flutter_version_model.dart';
import '../models/project_model.dart';
import '../models/project_registry_model.dart';
import '../utils/exceptions.dart';
import '../utils/file_utils.dart';
import 'base_service.dart';
import 'cache_service.dart';

/// Records the project roots FVM has seen for this cache, so `fvm list` can
/// tell which cached SDKs no known project pins.
class ProjectRegistryService extends ContextualService {
  const ProjectRegistryService(super.context);

  /// Canonical absolute identity for a project root, so the same project
  /// reached through a symlink or a relative path records only one entry.
  ///
  /// [p.join] ignores the working directory when [input] is already absolute.
  String _canonicalize(String input) {
    final normalized = p.normalize(p.join(context.workingDirectory, input));

    try {
      final directory = Directory(normalized);
      if (directory.existsSync()) return directory.resolveSymbolicLinksSync();
    } on FileSystemException {
      // Fall back to the lexical path when the link target cannot be resolved.
    }

    return normalized;
  }

  List<String> _readPaths() {
    final file = File(_registryPath);
    if (!file.existsSync()) return const [];

    final String contents;
    try {
      contents = file.readAsStringSync();
    } on FileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ProjectRegistryException(
          'Unable to read project registry at $_registryPath: ${error.message}',
        ),
        stackTrace,
      );
    }

    return parseProjectRegistry(contents, registryPath: _registryPath);
  }

  /// Replaces the registry with a fully written temporary file.
  void _writePaths(List<String> projects) {
    final file = File(_registryPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    final staged = File('${file.path}.$pid.tmp');

    try {
      staged.writeAsStringSync(encodeProjectRegistry(projects));
      staged.renameSync(file.path);
    } on FileSystemException catch (error, stackTrace) {
      if (staged.existsSync()) {
        try {
          staged.deleteSync();
        } on FileSystemException {
          // Leaving a stale temp file is better than masking the real error.
        }
      }
      Error.throwWithStackTrace(
        ProjectRegistryException(
          'Unable to write project registry at $_registryPath: ${error.message}',
        ),
        stackTrace,
      );
    }
  }

  /// The live config of the project at [path], or null when the directory is
  /// gone or no longer an FVM project.
  ///
  /// The bare catch handles `.fvmrc` JSON of the wrong shape. An array, for
  /// example, makes `ProjectConfig.fromMap` throw a `TypeError`, which
  /// `on Exception` would let escape.
  ProjectConfig? _configAt(String path) {
    try {
      final root = Directory(path);
      if (!root.existsSync()) return null;

      return ProjectConfig.loadFromDirectory(root);
    } catch (_) {
      return null;
    }
  }

  /// The installed SDK names [config] pins, as its Flutter version or through
  /// a flavor.
  ///
  /// Names come from [CacheService.installedNameOf] so they match what the
  /// cache actually stores. A pin is skipped when it cannot be parsed or
  /// resolves outside the cache directory, since it can never match an
  /// installed SDK either.
  List<({String? flavor, String version})> _versionReferencesOf(
    ProjectConfig config,
  ) {
    final cache = get<CacheService>();
    final references = <({String? flavor, String version})>[];

    void add(String? value, {String? flavor}) {
      if (value == null) return;
      try {
        final name = cache.installedNameOf(FlutterVersion.parse(value));
        if (name != null) references.add((flavor: flavor, version: name));
      } on FormatException {
        // Not a version FVM can parse.
      } on AppException {
        // Resolves outside the cache directory.
      }
    }

    add(config.flutter);
    final flavors = config.flavors;
    if (flavors != null) {
      for (final entry in flavors.entries) {
        add(entry.value, flavor: entry.key);
      }
    }

    return references;
  }

  /// Tries briefly to acquire the registry lock.
  bool _tryLock(RandomAccessFile handle) {
    const attempts = 20;
    const retry = Duration(milliseconds: 25);
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        handle.lockSync(FileLock.exclusive);

        return true;
      } on FileSystemException catch (error) {
        if (!isFileLockContentionError(error)) rethrow;
        if (attempt == attempts - 1) return false;
        sleep(retry);
      }
    }

    return false;
  }

  /// Serializes registry read-modify-write operations.
  void _withRegistryLock(void Function() action) {
    final lockFile = File('$_registryPath.lock');
    if (!lockFile.parent.existsSync()) {
      lockFile.parent.createSync(recursive: true);
    }

    final handle = lockFile.openSync(mode: FileMode.write);
    try {
      if (!_tryLock(handle)) {
        logger.debug('Project registry is locked by another FVM process');

        return;
      }
      try {
        action();
      } finally {
        handle.unlockSync();
      }
    } finally {
      handle.closeSync();
    }
  }

  String get _registryPath => context.projectsRegistryPath;

  /// Records [project] so `fvm list` can classify unused cached SDKs.
  void track(Project project) {
    if (context.isCI) {
      logger.debug('Skipping project registry tracking in CI');

      return;
    }

    try {
      final canonical = _canonicalize(project.path);
      _withRegistryLock(() {
        final known = _readPaths();
        final active = [
          for (final path in known)
            if (_configAt(path) != null) path,
        ];
        final alreadyKnown = active.any((path) => p.equals(path, canonical));
        if (alreadyKnown && active.length == known.length) return;
        if (!alreadyKnown) active.add(canonical);

        _writePaths(active);
      });
    } on Exception catch (error, stackTrace) {
      logger.warn('Failed to update project registry: $error');
      logger.logTrace(stackTrace);
    }
  }

  /// Which SDK versions the projects FVM knows about are using, together with
  /// the globally linked version, which counts as in use on its own.
  ///
  /// [includeCurrent] also counts a configured but unrecorded project.
  ///
  /// Throws [ProjectRegistryException] when the registry exists but cannot be
  /// read; callers decide whether that is fatal.
  CacheProjectUsage calculateUsage({Project? includeCurrent}) {
    final paths = <String>[];
    final referencesByVersion = <String, List<ProjectVersionReference>>{};

    void record(String path, ProjectConfig config) {
      paths.add(path);
      for (final reference in _versionReferencesOf(config)) {
        referencesByVersion.putIfAbsent(reference.version, () => []).add(
              ProjectVersionReference(
                projectPath: path,
                flavor: reference.flavor,
              ),
            );
      }
    }

    for (final path in _readPaths()) {
      final config = _configAt(path);
      if (config != null) record(path, config);
    }

    final current = includeCurrent;
    final currentConfig = current?.config;
    if (current != null && currentConfig != null) {
      final path = _canonicalize(current.path);
      if (!paths.any((known) => p.equals(known, path))) {
        record(path, currentConfig);
      }
    }

    return CacheProjectUsage(
      projectPaths: paths..sort(),
      projectReferencesByVersion: referencesByVersion,
      globalVersion: get<CacheService>().getGlobalVersion(),
    );
  }
}
