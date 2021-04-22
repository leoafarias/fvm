import '../../exceptions.dart';
import '../../fvm.dart';
import 'context.dart';

/// Service for FVM settings
class SettingsService {
  SettingsService._();
  static FvmSettings? _settings;

  /// Returns [FvmSettings]
  static Future<FvmSettings> read() async {
    try {
      if (_settings == null) {
        final payload = await ctx.settingsFile.readAsString();
        // Store in memory
        _settings = FvmSettings.fromJson(payload);
      }
      return Future.value(_settings);
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
        return FvmSettings.fromJson(payload);
      } else {
        return _settings!;
      }
    } on Exception {
      return FvmSettings();
    }
  }

  /// Saves FVM [settings]
  static Future<void> save(FvmSettings settings) async {
    try {
      if (!await ctx.settingsFile.exists()) {
        await ctx.settingsFile.create(recursive: true);
      }
      await ctx.settingsFile.writeAsString(settings.toJson());
      // Store in memory
      _settings = settings;
    } on Exception {
      throw FvmInternalError('Could not save FVM settings');
    }
  }
}
