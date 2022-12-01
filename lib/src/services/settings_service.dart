import 'dart:io';

import 'package:path/path.dart';

import '../../exceptions.dart';
import '../../fvm.dart';
import '../utils/logger.dart';
import 'context.dart';

/// Service for FVM settings
class SettingsService {
  SettingsService._();
  static SettingsDto? _settings;

  /// File for FVM Settings
  static File get settingsFile {
    return File(join(ctx.fvmHome.path, '.settings'));
  }

  /// Returns [SettingsDto]
  static Future<SettingsDto> read() async {
    try {
      if (_settings == null) {
        if (await settingsFile.exists()) {
          final payload = await settingsFile.readAsString();
          // Store in memory
          _settings = SettingsDto.fromJson(payload);
        } else {
          _settings = SettingsDto();
        }
      }
      return Future.value(_settings);
    } on Exception catch (err) {
      logger.trace(err.toString());
      return _settings = SettingsDto();
    }
  }

  /// Returns [SettingsDto] sync
  static SettingsDto readSync() {
    try {
      if (_settings == null) {
        if (settingsFile.existsSync()) {
          final payload = settingsFile.readAsStringSync();
          // Store in memory
          _settings = SettingsDto.fromJson(payload);
        } else {
          _settings = SettingsDto();
        }
      }
      return _settings!;
    } on Exception catch (err) {
      logger.trace(err.toString());
      return _settings = SettingsDto();
    }
  }

  /// Saves FVM [settings]
  static Future<void> save(SettingsDto settings) async {
    try {
      if (!await settingsFile.exists()) {
        await settingsFile.create(recursive: true);
      }
      await settingsFile.writeAsString(settings.toJson());
      // Store in memory
      _settings = settings;
    } on Exception {
      throw FvmInternalError('Could not save FVM settings');
    }
  }
}
