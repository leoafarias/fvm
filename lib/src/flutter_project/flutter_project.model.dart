import 'dart:convert';
import 'dart:io';
import 'package:fvm/constants.dart';

import 'package:fvm/src/flutter_project/fvm_config.model.dart';

import 'package:fvm/src/utils/helpers.dart';

import 'package:path/path.dart';
import 'package:pubspec_yaml/pubspec_yaml.dart';

class FlutterProject {
  final Directory projectDir;
  Directory _fvmConfigDir;
  File _configFile;
  String gitBranch;

  FlutterProject(this.projectDir, {this.gitBranch}) {
    _fvmConfigDir = Directory(join(projectDir.path, kFvmDirName));
    _configFile = File(join(_fvmConfigDir.path, kFvmConfigFileName));
  }

  factory FlutterProject.find() {
    return FlutterProject(_findProjectDir());
  }

  Future<void> setVersion(String version) async {
    final exists = await _configFile.exists();
    if (exists == false) {
      await _configFile.create(recursive: true);
    }

    await _configFile.writeAsString(jsonEncode(FvmConfig(version)));
    await createLink(sdkSymlink, File(join(kVersionsDir.path, version)));
  }

  /// Returns the current pinnned version of the project
  String get pinnedVersion {
    return _config.flutterSdkVersion;
  }

  /// Symlink of the sdk within the project
  Link get sdkSymlink {
    return Link(join(_fvmConfigDir.path, 'flutter_sdk'));
  }

  Future<bool> isFlutterProject() async {
    try {
      final isFlutter = pubspec.dependencies.firstWhere(
        // ignore: invalid_use_of_protected_member
        (dependency) => dependency.sdk != null,
        orElse: () => null,
      );
      return isFlutter != null;
    } on Exception {
      return false;
    }
  }

  String get name {
    return pubspec.name;
  }

  /// Pubspec file of the project
  PubspecYaml get pubspec {
    final pubspecFile = File(join(projectDir.path, 'pubspec.yaml'));
    final pubspec = pubspecFile.readAsStringSync();
    return pubspec.toPubspecYaml();
  }

  /// Project config found in the project.
  FvmConfig get _config {
    try {
      final jsonString = _configFile.readAsStringSync();
      final projectConfigMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return FvmConfig.fromJson(projectConfigMap);
    } on Exception {
      return FvmConfig(null);
    }
  }

  /// Recursive look up to find nested project directory
  static Directory _findProjectDir({Directory dir}) {
    dir ??= kWorkingDirectory;

    final isRootDir = rootPrefix(dir.path) == dir.path;
    final flutterProjectDir = Directory(dir.path);

    if (flutterProjectDir.existsSync()) return flutterProjectDir;
    // Return working directory if it has reached root
    if (isRootDir) {
      return kWorkingDirectory;
    }
    return _findProjectDir(dir: dir.parent);
  }
}
