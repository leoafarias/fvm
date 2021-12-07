import '../../exceptions.dart';
import '../../fvm.dart';
import '../utils/logger.dart';
import 'context.dart';

/// Service for FVM settings
class SettingsService {
  SettingsService._();
  static FvmSettings? _settings;

  /// Returns [FvmSettings]
  static Future<FvmSettings> read() async {
    try {
      if (_settings == null) {
        if (await ctx.settingsFile.exists()) {
          final payload = await ctx.settingsFile.readAsString();
          // Store in memory
          _settings = FvmSettings.fromJson(payload);
        } else {
          _settings = FvmSettings();
        }
      }
      return Future.value(_settings);
    } on Exception catch (err) {
      logger.trace(err.toString());
      return _settings = FvmSettings();
    }
  }

  /// Returns [FvmSettings] sync
  static FvmSettings readSync() {
    try {
      if (_settings == null) {
        if (ctx.settingsFile.existsSync()) {
          final payload = ctx.settingsFile.readAsStringSync();
          // Store in memory
          _settings = FvmSettings.fromJson(payload);
        } else {
          _settings = FvmSettings();
        }
      }
      return _settings!;
    } on Exception catch (err) {
      logger.trace(err.toString());
      return _settings = FvmSettings();
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
