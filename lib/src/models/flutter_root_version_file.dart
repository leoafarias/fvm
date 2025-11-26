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

  final String? frameworkVersion;

  final String? flutterVersion;
  final String? channel;
  final String? repositoryUrl;
  final String? frameworkRevision;
  final String? frameworkCommitDate;
  final String? engineRevision;
  final String? engineCommitDate;
  final String? engineContentHash;
  final String? engineBuildDate;
  final String? dartSdkVersion;
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
