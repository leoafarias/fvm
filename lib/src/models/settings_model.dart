import 'dart:convert';

import '../utils/pretty_json.dart';

/// FVM Settings model
class FvmSettings {
  /// Cache path configured in settings
  String cachePath;

  /// Settings if should skip setup
  bool skipSetup;

  /// If uses local git cache
  bool gitCache;

  /// Constructor
  FvmSettings({
    this.cachePath,
    this.skipSetup = false,
    this.gitCache = false,
  });

  /// Returns FvmSettings from [jsonString]
  factory FvmSettings.fromJson(String jsonString) {
    return FvmSettings.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  ///Returns FvmSettings from a map of values
  factory FvmSettings.fromMap(Map<String, dynamic> map) {
    return FvmSettings(
      cachePath: map['cachePath'] as String,
      skipSetup: map['skipSetup'] as bool ?? false,
      gitCache: map['gitCache'] as bool ?? false,
    );
  }

  /// Returns json of FvmSettings
  String toJson() => prettyJson(toMap());

  /// Returns a map of values from FvmSettings model
  Map<String, dynamic> toMap() {
    return {
      'cachePath': cachePath,
      'skipSetup': skipSetup,
      'gitCache': gitCache,
    };
  }
}
