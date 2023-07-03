import 'dart:convert';

import '../services/settings_service.dart';
import '../utils/pretty_json.dart';
import '../version.dart';

const _defaultDurationHours = 24;

/// Settings Dto
class SettingsDto {
  /// Cache path configured in settings
  String? cachePath;

  /// Installed version of FVM
  String? version;

  /// If uses local git cache
  bool gitCacheDisabled;

  /// Last git cache update
  DateTime? lastGitCacheUpdate;

  /// Duration until next git cache update
  Duration gitCacheUpdateInterval;

  /// Constructor
  SettingsDto._({
    this.cachePath,
    this.version,
    this.lastGitCacheUpdate,
    this.gitCacheDisabled = true,
    this.gitCacheUpdateInterval = const Duration(hours: _defaultDurationHours),
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

// Interval in hours for gitCacheUpdate
    final updateIntervalHours = map['gitCacheUpdateInterval'] as int?;

    return SettingsDto._(
      cachePath: map['cachePath'] as String?,
      version: map['version'] as String?,
      gitCacheDisabled: gitCacheDisabled,
      lastGitCacheUpdate: map['lastGitCacheUpdate'] == null
          ? null
          : DateTime.parse(map['lastGitCacheUpdate'] as String),
      gitCacheUpdateInterval: Duration(
        hours: updateIntervalHours ?? _defaultDurationHours,
      ),
    );
  }

  /// Returns the next date to update the git cache
  DateTime? get nextGitCacheUpdate {
    return lastGitCacheUpdate?.add(gitCacheUpdateInterval);
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
      'version': version,
      'gitCacheDisabled': gitCacheDisabled,
      'lastGitCacheUpdate': lastGitCacheUpdate?.toIso8601String(),
      'gitCacheUpdateInterval': gitCacheUpdateInterval.inHours,
    };
  }
}
