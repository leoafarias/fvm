import 'dart:convert';

import 'package:fvm/constants.dart';
import 'package:pretty_json/pretty_json.dart';

class Settings {
  String cachePath;
  String flutterProjectsDir;
  bool skipSetup;
  bool noAnalytics;
  bool advancedMode;
  List<String> projectPaths;

  Settings({
    this.cachePath,
    this.flutterProjectsDir,
    this.skipSetup = true,
    this.noAnalytics = false,
    this.advancedMode = false,
    this.projectPaths = const [],
  });

  factory Settings.fromJson(String jsonString) {
    return Settings.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  factory Settings.fromMap(Map<String, dynamic> json) {
    return Settings(
      cachePath: json['cachePath'] as String,
      flutterProjectsDir: json['flutterProjectsDir'] as String,
      projectPaths: (json['projectPaths'] as List<dynamic>).cast<String>(),
      skipSetup: json['skipSetup'] as bool ?? true,
      noAnalytics: json['noAnalytics'] as bool ?? false,
      advancedMode: json['advancedMode'] as bool ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cachePath': cachePath,
      'flutterProjectsDir': flutterProjectsDir,
      'skipSetup': skipSetup,
      'projectPaths': projectPaths,
      'noAnalytics': noAnalytics,
      'advancedMode': advancedMode,
    };
  }

  static Future<Settings> read() async {
    try {
      final payload = await kFvmSettings.readAsString();
      return Settings.fromJson(payload);
    } on Exception {
      return Settings();
    }
  }

  static Settings readSync() {
    try {
      final payload = kFvmSettings.readAsStringSync();
      return Settings.fromJson(payload);
    } on Exception {
      return Settings();
    }
  }

  Future<void> save() async {
    try {
      await kFvmSettings.writeAsString(prettyJson(toMap(), indent: 2));
    } on Exception {
      throw Exception('Could not save FVM config');
    }
  }
}
