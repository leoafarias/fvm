import 'dart:convert';

import '../services/settings_service.dart';
import '../utils/pretty_json.dart';

/// Settings Dto
class SettingsDto {
  /// Cache path configured in settings
  String? cachePath;

  /// Settings if should skip setup
  bool skipSetup;

  /// Installed version of FVM
  String? fvmVersion;

  /// If uses local git cache
  bool gitCacheDisabled;

  /// Last git cache update
  DateTime? lastGitCacheUpdate;

  /// Constructor
  SettingsDto({
    this.cachePath,
    this.fvmVersion,
    this.lastGitCacheUpdate,
    this.skipSetup = false,
    this.gitCacheDisabled = false,
  });

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

    return SettingsDto(
      cachePath: map['cachePath'] as String?,
      fvmVersion: map['fvmVersion'] as String?,
      skipSetup: map['skipSetup'] as bool? ?? false,
      gitCacheDisabled: gitCacheDisabled,
      lastGitCacheUpdate: map['lastGitCacheUpdate'] == null
          ? null
          : DateTime.parse(map['lastGitCacheUpdate'] as String),
    );
  }

  /// Returns the next date to update the git cache
  DateTime? get nextGitCacheUpdate {
    return lastGitCacheUpdate?.add(const Duration(days: 7));
  }

  /// Returns if git cache should be updated
  bool get shouldUpdateGitCache {
    return lastGitCacheUpdate == null ||
        nextGitCacheUpdate == null ||
        DateTime.now().isAfter(nextGitCacheUpdate!);
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
      'fvmVersion': fvmVersion,
      'skipSetup': skipSetup,
      'gitCacheDisabled': gitCacheDisabled,
      'lastGitCacheUpdate': lastGitCacheUpdate?.toIso8601String(),
    };
  }
}
