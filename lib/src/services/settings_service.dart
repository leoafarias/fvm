import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/pretty_json.dart';

class SettingsService {
  static Future<FvmSettings> read() async {
    try {
      final payload = await kFvmSettings.readAsString();
      return FvmSettings.fromJson(payload);
    } on Exception {
      return FvmSettings();
    }
  }

  static FvmSettings readSync() {
    try {
      final payload = kFvmSettings.readAsStringSync();
      return FvmSettings.fromJson(payload);
    } on Exception {
      return FvmSettings();
    }
  }

  static Future<void> save(FvmSettings settings) async {
    try {
      await kFvmSettings.writeAsString(prettyJson(settings.toMap()));
    } on Exception {
      throw Exception('Could not save FVM config');
    }
  }
}
