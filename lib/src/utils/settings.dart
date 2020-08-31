import 'dart:convert';

import 'package:fvm/constants.dart';

class FvmSettings {
  String cachePath;
  FvmSettings({this.cachePath});

  factory FvmSettings.fromMap(Map<String, dynamic> json) {
    return FvmSettings(cachePath: json['cachePath'] as String);
  }

  Map<String, dynamic> toMap() {
    return {
      'cachePath': cachePath,
    };
  }

  static FvmSettings read() {
    try {
      final payload = kFvmSettings.readAsStringSync();
      return FvmSettings.fromMap(jsonDecode(payload) as Map<String, dynamic>);
    } on Exception {
      return FvmSettings();
    }
  }

  Future<void> save() async {
    try {
      await kFvmSettings.writeAsString(jsonEncode(toMap()));
    } on Exception {
      throw Exception('Could not save FVM config');
    }
  }
}
