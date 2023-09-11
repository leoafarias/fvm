import 'dart:convert';

import 'package:fvm/src/version.g.dart';

import '../services/settings_service.dart';
import '../utils/pretty_json.dart';

/// Settings Dto
class SettingsDto {
  /// Cache path configured in settings
  String? cachePath;

  /// Installed version of FVM
  String? version;

  /// If uses local git cache
  bool gitCacheDisabled;

  /// Constructor
  SettingsDto._({
    this.cachePath,
    this.version,
    this.gitCacheDisabled = true,
  });

  /// Empty FvmSettings constructor
  factory SettingsDto.empty() {
    return SettingsDto._(version: packageVersion);
  }

  /// Returns FvmSettings from [jsonString]
  factory SettingsDto.fromJson(String jsonString) {
    return SettingsDto.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  ///Returns FvmSettings from a map of values
  factory SettingsDto.fromMap(Map<String, dynamic> map) {
    bool gitCacheDisabled;

    if (map['gitCache'] != null) {
      // Backwards compatibility supports
      gitCacheDisabled = !(map['gitCache'].toString() == 'true');
    } else {
      gitCacheDisabled = map['gitCacheDisabled'] as bool? ?? false;
    }

    return SettingsDto._(
      cachePath: map['cachePath'] as String?,
      version: map['version'] as String?,
      gitCacheDisabled: gitCacheDisabled,
    );
  }

  /// Saves settings dto locally
  Future<void> save() async {
    await SettingsService.save(this);
  }

  /// Returns json of FvmSettings
  String toJson() => prettyJson(toMap());

  /// Returns a map of values from FvmSettings model
  Map<String, dynamic> toMap() {
    return {
      'cachePath': cachePath,
      'version': version,
      'gitCacheDisabled': gitCacheDisabled,
    };
  }
}
