import 'dart:convert';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart';

part 'flutter_root_version_file.mapper.dart';

/// Represents the contents of `$FLUTTER_ROOT/bin/cache/flutter.version.json`.
///
/// This file was introduced in Flutter 3.13 and becomes the sole version source
/// in Flutter 3.38+ (replacing the legacy `$FLUTTER_ROOT/version` file).
///
/// Fields are optional because the file format can evolve over time and custom
/// builds might omit values.
@MappableClass(ignoreNull: true)
class FlutterRootVersionFile with FlutterRootVersionFileMappable {
  static final fromMap = FlutterRootVersionFileMapper.fromMap;
  static final fromJson = FlutterRootVersionFileMapper.fromJson;

  /// The framework version string (e.g., "3.19.0").
  final String? frameworkVersion;

  /// The Flutter version string, may differ from [frameworkVersion] in some builds.
  final String? flutterVersion;

  /// The release channel (e.g., "stable", "beta", "dev", "master").
  final String? channel;

  /// The URL of the Flutter repository.
  final String? repositoryUrl;

  /// The git commit hash of the framework.
  final String? frameworkRevision;

  /// The commit date of the framework revision.
  final String? frameworkCommitDate;

  /// The git commit hash of the Flutter engine.
  final String? engineRevision;

  /// The commit date of the engine revision.
  final String? engineCommitDate;

  /// The content hash of the engine artifacts.
  final String? engineContentHash;

  /// The build date of the engine.
  final String? engineBuildDate;

  /// The Dart SDK version bundled with this Flutter version.
  final String? dartSdkVersion;

  /// The DevTools version bundled with this Flutter version.
  final String? devToolsVersion;

  const FlutterRootVersionFile({
    this.frameworkVersion,
    this.flutterVersion,
    this.channel,
    this.repositoryUrl,
    this.frameworkRevision,
    this.frameworkCommitDate,
    this.engineRevision,
    this.engineCommitDate,
    this.engineContentHash,
    this.engineBuildDate,
    this.dartSdkVersion,
    this.devToolsVersion,
  });

  /// Attempts to load and parse the version file from a known Flutter SDK root.
  ///
  /// Returns `null` if the file doesn't exist or can't be parsed.
  static FlutterRootVersionFile? tryLoadFromRoot(Directory flutterRoot) {
    final file =
        File(join(flutterRoot.path, 'bin', 'cache', 'flutter.version.json'));

    return tryLoadFromFile(file);
  }

  /// Attempts to parse the given file as a Flutter root version file.
  ///
  /// Returns `null` if the file doesn't exist or can't be parsed.
  static FlutterRootVersionFile? tryLoadFromFile(File file) {
    if (!file.existsSync()) return null;

    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      return FlutterRootVersionFile.fromMap(json);
    } catch (_) {
      return null;
    }
  }

  /// Primary version string exposed by the Flutter tool.
  ///
  /// `flutterVersion` is preferred when present; otherwise fall back to
  /// `frameworkVersion` to mirror Flutter's own usage.
  String? get primaryVersion {
    final value = flutterVersion ?? frameworkVersion;
    if (value == null) return null;
    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }
}
