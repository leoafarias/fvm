import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/config_model.dart';
import '../models/flutter_version_model.dart';
import '../models/project_model.dart';
import '../models/project_registry_model.dart';
import '../utils/exceptions.dart';
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

  /// Stages the new contents beside the registry and renames it into place, so
  /// a failed write can never leave a partial `projects.json` behind. Renaming
  /// over an existing file replaces it on every platform `dart:io` supports.
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
  /// A registry entry is only a hint, so an unreadable project is skipped
  /// rather than reported: one broken `.fvmrc` must not break `fvm list`.
  ///
  /// The bare catch is deliberate. A `.fvmrc` holding valid JSON of the wrong
  /// shape (an array, say) makes `ProjectConfig.fromMap` throw a `TypeError`,
  /// which `on Exception` would let escape.
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
  /// cache actually stores. A pin is silently dropped when it cannot name an
  /// installed SDK at all, since it can never match one either.
  Set<String> _pinnedVersionsOf(ProjectConfig config) {
    final cache = get<CacheService>();
    final versions = <String>{};
    for (final value in [config.flutter, ...?config.flavors?.values]) {
      if (value == null) continue;
      try {
        final name = cache.installedNameOf(FlutterVersion.parse(value));
        if (name != null) versions.add(name);
      } on FormatException {
        // Not a version FVM can parse.
      } on AppException {
        // Resolves outside the cache directory.
      }
    }

    return versions;
  }

  /// Polls for the registry lock, giving up rather than waiting on a hung
  /// process: tracking is best-effort, so skipping it always beats stalling
  /// the command that triggered it.
  bool _tryLock(RandomAccessFile handle) {
    for (var attempt = 0; attempt < 20; attempt++) {
      try {
        handle.lockSync(FileLock.exclusive);

        return true;
      } on FileSystemException {
        // Held by another FVM process.
      }
      sleep(const Duration(milliseconds: 25));
    }

    return false;
  }

  /// Runs [action] holding an exclusive lock on the registry.
  ///
  /// Only writers need this. A reader always sees a whole file because
  /// [_writePaths] renames a fully written one into place, but concurrent
  /// `fvm use`/`fvm install` runs in a monorepo would otherwise interleave
  /// read-modify-write and drop each other's registrations.
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
  ///
  /// Registry bookkeeping is secondary and never fails the parent command.
  void track(Project project) {
    if (context.isCI) {
      logger.debug('Skipping project registry tracking in CI');

      return;
    }

    try {
      final canonical = _canonicalize(project.path);
      _withRegistryLock(() {
        final known = _readPaths();
        if (known.any((path) => p.equals(path, canonical))) return;

        _writePaths([...known, canonical]);
      });
    } on Exception catch (error, stackTrace) {
      logger.warn('Failed to update project registry: $error');
      logger.logTrace(stackTrace);
    }
  }

  /// Which SDK versions the projects FVM knows about are using, together with
  /// the globally linked version, which counts as in use on its own.
  ///
  /// Pass [includeCurrent] to count a configured project that has not been
  /// recorded yet, so `fvm list` never calls the current project's SDK unused.
  ///
  /// Throws [ProjectRegistryException] when the registry exists but cannot be
  /// read; callers decide whether that is fatal.
  CacheProjectUsage calculateUsage({Project? includeCurrent}) {
    final paths = <String>[];
    final countByVersion = <String, int>{};

    void record(String path, ProjectConfig config) {
      paths.add(path);
      for (final version in _pinnedVersionsOf(config)) {
        countByVersion[version] = (countByVersion[version] ?? 0) + 1;
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
      projectCountByVersion: countByVersion,
      globalVersion: get<CacheService>().getGlobalVersion(),
    );
  }
}
