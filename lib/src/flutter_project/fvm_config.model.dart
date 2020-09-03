import 'dart:convert';

import 'package:pretty_json/pretty_json.dart';

class FvmConfig {
  final String flutterSdkVersion;
  FvmConfig(this.flutterSdkVersion);

  factory FvmConfig.fromJson(String jsonString) {
    return FvmConfig.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  FvmConfig.fromMap(Map<String, dynamic> json)
      : flutterSdkVersion = json['flutterSdkVersion'] as String;

  Map<String, dynamic> toMap() => {
        'flutterSdkVersion': flutterSdkVersion,
      };

  String toJson() => prettyJson(toMap(), indent: 2);
}
