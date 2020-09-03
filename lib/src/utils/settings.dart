import 'dart:convert';

import 'package:fvm/constants.dart';
import 'package:pretty_json/pretty_json.dart';

class FvmSettings {
  String cachePath;
  String flutterProjectsDir;
  bool skipSetup;
  bool noAnalytics;

  FvmSettings({
    this.cachePath,
    this.flutterProjectsDir,
    this.skipSetup,
    this.noAnalytics,
  });

  factory FvmSettings.fromJson(String jsonString) {
    return FvmSettings.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  factory FvmSettings.fromMap(Map<String, dynamic> json) {
    return FvmSettings(
      cachePath: json['cachePath'] as String,
      flutterProjectsDir: json['flutterProjectsDir'] as String,
      skipSetup: json['skipSetup'] as bool,
      noAnalytics: json['noAnalytics'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cachePath': cachePath,
      'flutterProjectsDir': flutterProjectsDir,
      'skipSetup': skipSetup,
      'noAnalytics': noAnalytics,
    };
  }

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

  Future<void> save() async {
    try {
      await kFvmSettings.writeAsString(prettyJson(toMap(), indent: 2));
    } on Exception {
      throw Exception('Could not save FVM config');
    }
  }
}
