import 'dart:convert';
import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/utils/helpers.dart';

class ProjectConfig {
  final String flutterSdkVersion;
  ProjectConfig(this.flutterSdkVersion);

  ProjectConfig.fromJson(Map<String, dynamic> json)
      : flutterSdkVersion = json['flutterSdkVersion'] as String;

  Map<String, dynamic> toJson() => {'flutterSdkVersion': flutterSdkVersion};
}

void updateProjectConfig(String version) {
  if (kProjectFvmConfigJson.existsSync() == false) {
    kProjectFvmConfigJson.createSync(recursive: true);
  }
  saveProjectConfig(ProjectConfig(version));
  updateFlutterSdkBinLink();
}

void updateFlutterSdkBinLink() {
  final flutterSdk = getFlutterSdkPath();
  createLink(kProjectFvmSdkSymlink, File(flutterSdk));
}

ProjectConfig readProjectConfig() {
  final jsonString = kProjectFvmConfigJson.readAsStringSync();
  final projectConfigMap = jsonDecode(jsonString) as Map<String, dynamic>;
  return ProjectConfig.fromJson(projectConfigMap);
}

void saveProjectConfig(ProjectConfig config) {
  kProjectFvmConfigJson.writeAsStringSync(jsonEncode(config));
}
