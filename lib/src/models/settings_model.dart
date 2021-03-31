import 'dart:convert';

/// FVM Settings model
class FvmSettings {
  /// Cache path configured in settings
  String cachePath;

  /// Settings if should skip setup
  bool skipSetup;

  /// Setting if should turn off analytics
  bool noAnalytics;

  /// If uses local git cache
  bool gitCache;

  /// Constructor
  FvmSettings({
    this.cachePath,
    this.skipSetup = false,
    this.noAnalytics = false,
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
      noAnalytics: map['noAnalytics'] as bool ?? false,
    );
  }

  /// Returns a map of values from FvmSettings model
  Map<String, dynamic> toMap() {
    return {
      'cachePath': cachePath,
      'skipSetup': skipSetup,
      'noAnalytics': noAnalytics,
      'gitCache': gitCache,
    };
  }
}
