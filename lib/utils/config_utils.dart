import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';

import 'logger.dart';

/// Configure fvm options.

class ConfigUtils {
  static ConfigUtils _instance;

  ConfigUtils._() {
    _readConfig();
  }

  /// Configure fvm options.
  factory ConfigUtils() {
    _instance ??= ConfigUtils._();
    return _instance;
  }

  final Map<String, String> _config = {};

  Map<String, String> _readConfig() {
    if (!kConfigFile.existsSync()) {
      kConfigFile.createSync(recursive: true);
    }
    try {
      final savedValueMap = json.decode(kConfigFile.readAsStringSync());
      for (final key in savedValueMap.keys) {
        if (key is String) {
          _config[key] = savedValueMap[key] as String;
        }
      }
    } on Exception catch (e) {
      ExceptionCouldNotReadConfig('$e');
    }
    return _config;
  }

  void _commit() {
    if (!kConfigFile.existsSync()) {
      kConfigFile.createSync(recursive: true);
    }
    kConfigFile.writeAsStringSync(json.encode(_config));
  }

  /// Set config value
  void setValue(String key, String value) {
    _config[key] = value;
    _commit();
  }

  /// Get config value
  String getValue(String key) {
    return _config[key];
  }

  /// config flutter stored path
  void configFlutterStoredPath(String path) {
    final type = FileSystemEntity.typeSync(path, followLinks: true);
    if (type == FileSystemEntityType.directory) {
      setValue(kConfigFlutterStoredKey, path);
    } else if (type == FileSystemEntityType.notFound) {
      Directory(path).createSync(recursive: true);
      setValue(kConfigFlutterStoredKey, path);
    } else {
      throw const ExceptionErrorFlutterPath();
    }
  }

  /// Config the flutter git remote.
  ///
  /// This config will only affect the new version, the git url of the existing version will not change.
  ///
  /// Things to do in the future:
  /// Add a new command to change the remote url corresponding to the existing version.
  void configGitRemoteUrl(String gitRemoteUrl) {
    setValue(kConfigGitRemoteUrlKey, gitRemoteUrl);
  }

  /// Removes Config file
  void removeConfig() async {
    if (await kConfigFile.exists()) {
      await kConfigFile.delete();
    }
  }

  /// Get git remote url of flutter.
  String getGitRemoteUrl() {
    final url = _config[kConfigGitRemoteUrlKey];
    if (url == null || url.trim().isEmpty) {
      return kFlutterRepo;
    }
    checkFlutterRemote(url);
    return url;
  }

  /// get flutter stored path.
  String getStoredPath() {
    final path = getValue(kConfigFlutterStoredKey);

    if (path == null) {
      return null;
    }

    final type = FileSystemEntity.typeSync(path, followLinks: true);
    if (type == FileSystemEntityType.directory) {
      return path;
    } else if (type == FileSystemEntityType.notFound) {
      Directory(path).createSync(recursive: true);
      return path;
    }

    return null;
  }

  /// show all config
  String displayAllConfig() {
    final sb = StringBuffer();
    for (final key in _config.keys) {
      final value = _config[key];
      sb.writeln('$key : $value');
    }

    return sb.toString();
  }
}
