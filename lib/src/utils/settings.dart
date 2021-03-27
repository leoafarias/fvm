import 'dart:convert';

import 'package:fvm/constants.dart';
import 'package:fvm/src/utils/pretty_json.dart';

class Settings {
  String cachePath;

  bool skipSetup;
  bool noAnalytics;

  Settings({
    this.cachePath,
    this.skipSetup = true,
    this.noAnalytics = false,
  });

  factory Settings.fromJson(String jsonString) {
    return Settings.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  factory Settings.fromMap(Map<String, dynamic> json) {
    return Settings(
      cachePath: json['cachePath'] as String,
      skipSetup: json['skipSetup'] as bool ?? true,
      noAnalytics: json['noAnalytics'] as bool ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cachePath': cachePath,
      'skipSetup': skipSetup,
      'noAnalytics': noAnalytics,
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
      await kFvmSettings.writeAsString(prettyJson(toMap()));
    } on Exception {
      throw Exception('Could not save FVM config');
    }
  }
}
