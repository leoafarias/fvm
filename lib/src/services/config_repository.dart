import 'dart:io';

import 'package:fvm/src/utils/pretty_json.dart';
import 'package:fvm/src/version.g.dart';

import '../../fvm.dart';
import '../utils/logger.dart';

/// Service to manage FVM Config
class ConfigRepository {
  /// Path where config is stored
  final String _configPath;

  ConfigRepository(this._configPath);

  /// File for FVM config
  File get _configFile => File(_configPath);

  /// Returns [ConfigDto] from config file
  /// Can pass [commandLineArgs] to override config
  ConfigDto load({
    List<String>? commandLineArgs,
  }) {
    try {
      return ConfigDto.fromConfig(
        configPath: _configPath,
        args: commandLineArgs,
      );
    } on Exception catch (err) {
      logger.detail(err.toString());
      rethrow;
    }
  }

  /// Saves FVM [settings]
  void save(ConfigDto config) async {
    if (!_configFile.existsSync()) {
      _configFile.createSync(recursive: true);
    }

    final mapToSave = {
      'fvmVersion': packageVersion,
      ...config.toMap(),
    };

    _configFile.writeAsStringSync(prettyJson(mapToSave));
  }
}
