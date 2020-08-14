import 'dart:convert';
import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/src/modules/flutter_tools/flutter_helpers.dart';
import 'package:fvm/utils/pretty_print.dart';
import 'package:path/path.dart' as path;

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
  PrettyPrint.success('Project now uses Flutter: $version');
}

void updateFlutterSdkBinLink() {
  final flutterSdk = getFlutterSdkPath();
  createLink(kProjectFvmSdkSymlink, File(flutterSdk));
}

ProjectConfig readProjectConfig({File projectConfig}) {
  try {
    projectConfig ??= kProjectFvmConfigJson;
    final jsonString = projectConfig.readAsStringSync();
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

Future<void> getLocalFlutterProjects(String dirPath) async {
  var dir = Directory(dirPath);
  List contents = dir.listSync(recursive: true);
  for (final ioEntity in contents) {
    if (ioEntity is Directory) {
      final pubspec = File(path.join(ioEntity.path, 'pubspec.yaml'));
      // TODO move fvm_config.json to constant
      final fvmConfig =
          File(path.join(ioEntity.path, kFvmDirName, 'fvm_config.json'));

      if (pubspec.existsSync() && fvmConfig.existsSync()) {}
    }
  }
}
