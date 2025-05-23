import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/flutter_version_model.dart';
import '../services/base_service.dart';
import '../services/logger_service.dart';
import '../utils/context.dart';
import '../workflows/ensure_cache.workflow.dart';
import '../workflows/validate_flutter_version.workflow.dart';

/// Base Command
abstract class BaseFvmCommand extends Command<int> {
  @protected
  final FvmContext context;

  BaseFvmCommand(this.context);

  Logger get logger => context.get();

  T get<T extends Contextual>() => context.get();

  /// Common pattern used by global, install, flavor, spawn, and use commands
  ///
  /// Takes a version string, validates it, and ensures it's cached locally.
  /// Returns the cached version ready for use.
  Future<CacheFlutterVersion> resolveAndEnsureVersion(
    String version, {
    bool force = false,
    bool shouldInstall = false,
  }) async {
    final validateFlutterVersion = ValidateFlutterVersionWorkflow(context);
    final ensureCache = EnsureCacheWorkflow(context);

    final flutterVersion = validateFlutterVersion(version, force: force);
    final cacheVersion = await ensureCache(
      flutterVersion,
      force: force,
      shouldInstall: shouldInstall,
    );

    return cacheVersion;
  }

  /// Validates a version string and returns FlutterVersion object
  FlutterVersion validateVersion(String version, {bool force = false}) {
    final validateFlutterVersion = ValidateFlutterVersionWorkflow(context);

    return validateFlutterVersion(version, force: force);
  }

  /// Ensures a FlutterVersion is cached locally
  Future<CacheFlutterVersion> ensureVersionCached(
    FlutterVersion version, {
    bool force = false,
    bool shouldInstall = false,
  }) async {
    final ensureCache = EnsureCacheWorkflow(context);

    return await ensureCache(
      version,
      force: force,
      shouldInstall: shouldInstall,
    );
  }

  @override
  String get invocation => 'fvm $name';

  // Override to make sure commands are visible by default
  @override
  bool get hidden => false;
}

extension CommandExtension on Command {
  /// Checks if the command-line option named [name] was parsed.
  bool wasParsed(String name) => argResults!.wasParsed(name);

  /// Gets the parsed command-line option named [name] as `bool`.
  bool boolArg(String name) => argResults![name] == true;

  /// Gets the parsed command-line option named [name] as `String`.
  String? stringArg(String name) {
    final arg = argResults![name] as String?;
    if (arg == 'null' || (arg == null || arg.isEmpty)) {
      return null;
    }

    return arg;
  }

  int? intArg(String name) {
    final arg = stringArg(name);

    return arg == null ? null : int.tryParse(arg);
  }

  /// Gets the parsed command-line option named [name] as `List<String>`.
  // ignore: prefer-correct-json-casts
  List<String?> stringsArg(String name) => argResults![name] as List<String>;
}
