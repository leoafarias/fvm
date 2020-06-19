import 'dart:convert';
import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/print.dart';

class ProjectConfig {
  final String flutterSdkVersion;
  ProjectConfig(this.flutterSdkVersion);

  ProjectConfig.fromJson(Map<String, dynamic> json)
      : flutterSdkVersion = json['flutterSdkVersion'] as String;

  Map<String, dynamic> toJson() => {'flutterSdkVersion': flutterSdkVersion};
}

void setAsProjectVersion(String version) {
  if (kProjectFvmConfigJson.existsSync() == false) {
    kProjectFvmConfigJson.createSync(recursive: true);
  }
  saveProjectConfig(ProjectConfig(version));
  updateFlutterSdkBinLink();
  Print.success('Project now uses Flutter: $version');
}

void updateFlutterSdkBinLink() {
  final flutterSdk = getFlutterSdkPath();
  createLink(kProjectFvmSdkSymlink, File(flutterSdk));
}

ProjectConfig readProjectConfig() {
  try {
    final jsonString = kProjectFvmConfigJson.readAsStringSync();
    final projectConfigMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return ProjectConfig.fromJson(projectConfigMap);
  } on Exception {
    throw ExceptionProjectConfigNotFound();
  }
}

/// Returns version from project config
String getConfigFlutterVersion() {
  try {
    final config = readProjectConfig();
    return config.flutterSdkVersion;
  } on Exception {
    return null;
  }
}

void saveProjectConfig(ProjectConfig config) {
  kProjectFvmConfigJson.writeAsStringSync(jsonEncode(config));
}
