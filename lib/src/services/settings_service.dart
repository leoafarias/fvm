import '../../constants.dart';
import '../../fvm.dart';

/// Service for FVM settings
class SettingsService {
  /// Returns [FvmSettings]
  static Future<FvmSettings> read() async {
    try {
      final payload = await kFvmSettings.readAsString();
      return FvmSettings.fromJson(payload);
    } on Exception {
      return FvmSettings();
    }
  }

  /// Returns [FvmSettings] sync
  static FvmSettings readSync() {
    try {
      final payload = kFvmSettings.readAsStringSync();
      return FvmSettings.fromJson(payload);
    } on Exception {
      return FvmSettings();
    }
  }

  /// Saves FVM [settings]
  static Future<void> save(FvmSettings settings) async {
    try {
      await kFvmSettings.writeAsString(settings.toJson());
    } on Exception {
      throw Exception('Could not save FVM config');
    }
  }
}
