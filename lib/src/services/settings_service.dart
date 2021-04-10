import '../../fvm.dart';
import 'context.dart';

/// Service for FVM settings
class SettingsService {
  SettingsService._();
  static FvmSettings _settings;

  /// Returns [FvmSettings]
  static Future<FvmSettings> read() async {
    try {
      if (_settings == null) {
        final payload = await ctx.settingsFile.readAsString();
        // Store in memory
        _settings = FvmSettings.fromJson(payload);
      }
      return _settings;
    } on Exception {
      return FvmSettings();
    }
  }

  /// Returns [FvmSettings] sync
  static FvmSettings readSync() {
    try {
      if (_settings == null) {
        final payload = ctx.settingsFile.readAsStringSync();
        // Store in memory
        _settings = FvmSettings.fromJson(payload);
      }
      return _settings;
    } on Exception {
      return FvmSettings();
    }
  }

  /// Saves FVM [settings]
  static Future<void> save(FvmSettings settings) async {
    try {
      await ctx.settingsFile.writeAsString(settings.toJson());
      // Store in memory
      _settings = settings;
    } on Exception {
      throw Exception('Could not save FVM config');
    }
  }
}
