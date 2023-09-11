import 'dart:convert';

/// FVM Config model
class ProjectConfig {
  /// Flutter SDK version configured
  String? flutter;
  String? flutterSdkVersion;

  /// Flavors configured
  Map<String, dynamic>? flavors;

  /// Constructor
  ProjectConfig({
    required this.flutter,
    this.flavors,
  });

  factory ProjectConfig.empty() {
    return ProjectConfig(
      flutter: null,
      flavors: {},
    );
  }

  /// Returns FvmConfig  from [jsonString]
  factory ProjectConfig.fromJson(String jsonString) {
    return ProjectConfig.fromMap(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Returns FvmConfig from a map
  factory ProjectConfig.fromMap(Map<String, dynamic> map) {
    return ProjectConfig(
      flutter: map['flutterSdkVersion'] ?? map['flutter'] as String?,
      flavors: map['flavors'] as Map<String, dynamic>?,
    );
  }

  /// Returns a map of values from FvmConfig
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'flutterSdkVersion': flutter,
    };
    // Doing this to clean up flavors payload from config
    if (flavors != null && flavors!.isNotEmpty) {
      map['flavors'] = flavors;
    }
    return map;
  }
}
