import 'dart:convert';

class FvmSettings {
  String cachePath;

  bool skipSetup;
  bool noAnalytics;

  FvmSettings({
    this.cachePath,
    this.skipSetup = true,
    this.noAnalytics = false,
  });

  factory FvmSettings.fromJson(String jsonString) {
    return FvmSettings.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  factory FvmSettings.fromMap(Map<String, dynamic> json) {
    return FvmSettings(
      cachePath: json['cachePath'] as String,
      skipSetup: json['skipSetup'] as bool ?? true,
      noAnalytics: json['noAnalytics'] as bool ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cachePath': cachePath,
      'skipSetup': skipSetup,
      'noAnalytics': noAnalytics,
    };
  }
}
