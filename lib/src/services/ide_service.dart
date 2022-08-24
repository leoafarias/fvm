import 'dart:convert';
import 'dart:io';

import '../utils/console_utils.dart';
import '../utils/helpers.dart';
import '../utils/logger.dart';

/// Default VSCode config
const _defaultConfig = {
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  // Remove .fvm files from search
  "search.exclude": {"**/.fvm": true},
  // Remove from file watching
  "files.watcherExclude": {"**/.fvm": true}
};

const _vscSettingPath = '.vscode/settings.json';

/// For manage VSCode settings
class IDEService {
  IDEService._();

  /// Configure IDEs for better support for different development environments.
  /// [ask] : ask for confirmation
  static Future<void> updateSetting({bool ask = true}) async {
    if (ask) {
      final resume =
          await confirm('Would you like to configure VSCode for FVM?');
      Logger.spacer();
      if (!resume) {
        return;
      }
    }

    await _updateVSCodeSetting();
  }

  /// Write `dart.flutterSdkPath` to `.vscode/setting.json`
  static Future<void> _updateVSCodeSetting() async {
    /// Read now settings
    final file = File(_vscSettingPath);
    var settingFile = '{}';

    try {
      settingFile = await file.readAsString();
    } on Exception catch (_) {
      // If file does not exist, create it
      await file.create(recursive: true);
    }

    final settings = json.decode(settingFile) as Map<String, dynamic>;

    /// Merge new setting
    final newSettings = {
      ...settings,
      ..._defaultConfig,
    };

    final newSettingsStr = JsonEncoder.withIndent('  ').convert(newSettings);

    /// Already exists && newSettings != settings
    if (settings.keys.isNotEmpty && !mapEquals(_defaultConfig, newSettings)) {
      Logger.warning('VSCode settings already exist.\nAuto merge result:');
      Logger.divider();
      Logger.info(newSettingsStr);
      Logger.divider();
      final resume = await confirm('Write merged result to file?');
      if (!resume) {
        Logger.info('VSCode settings not updated.');
        Logger.spacer();
        return;
      }
    }

    /// Write result
    await file.writeAsString(newSettingsStr);
    Logger.fine('VSCode settings updated.');
    Logger.spacer();
  }
}
