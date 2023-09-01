import 'dart:convert';
import 'dart:io';

import '../utils/helpers.dart';
import '../utils/logger.dart';
import '../utils/pretty_json.dart';

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

  /// Write `dart.flutterSdkPath` to `.vscode/setting.json`
  static Future<void> configureVsCodeSettings() async {
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

    final newSettingsStr = prettyJson(newSettings);
    final oldSettingsStr = prettyJson(settings);

    /// Already exists && newSettings != settings
    if (settings.keys.isNotEmpty && !mapEquals(_defaultConfig, newSettings)) {
      logger
        ..warn('VSCode settings already exist.')
        ..info('Settings before merging:\n$oldSettingsStr')
        ..divider
        ..info('Auto merged result:\n$newSettingsStr')
        ..divider;
      final resume = logger.confirm(
        'Write merged result to file?',
        defaultValue: false,
      );
      if (!resume) {
        logger
          ..info('VSCode settings not updated.')
          ..spacer;
        return;
      }
    }

    /// Write result
    await file.writeAsString(newSettingsStr);
    logger
      ..success('VSCode settings updated.')
      ..spacer;
  }
}
