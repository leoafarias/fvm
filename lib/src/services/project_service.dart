import 'dart:convert';
import 'dart:io';

import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/io_utils.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/utils/pretty_json.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';
import 'package:pubspec2/pubspec2.dart';

import '../../constants.dart';

/// Flutter Project Services
/// APIs for interacting with local Flutter projects
class ProjectService {
  ProjectService();

  static ProjectService get instance => ctx.get<ProjectService>();

  /// Returns projects by providing a [directory]
  Future<Project> loadByDirectory(Directory directory) async {
    final configFile = File(
      join(directory.path, kFvmDirName, kFvmConfigFileName),
    );

    final pubspecFile = File(join(directory.path, 'pubspec.yaml'));

    ProjectConfig? config;

    if (configFile.existsSync()) {
      final jsonString = configFile.readAsStringSync();
      config = ProjectConfig.fromJson(jsonString);
    }

    PubSpec? pubspec;
    if (pubspecFile.existsSync()) {
      final jsonString = pubspecFile.readAsStringSync();
      pubspec = PubSpec.fromYamlString(jsonString);
    }

    return Project(
      projectDir: directory,
      pubspec: pubspec,
      config: config,
    );
  }

  /// Returns a list of projects by providing a list of [paths]
  Future<List<Project>> fetchProjects(List<Directory> paths) async {
    return Future.wait(paths.map(loadByDirectory));
  }

  /// Adds to .gitignore paths that should be ignored for fvm
  void addToGitignore(Project project, String pathToAdd) {
    bool alreadyExists = false;

    // Check if .gitignore exists, and if not, create it.
    if (!project.gitignoreFile.existsSync()) {
      project.gitignoreFile.createSync();
    }

    // Read existing lines.
    List<String> lines = project.gitignoreFile.readAsLinesSync();

    // Check if path already exists in .gitignore
    for (var line in lines) {
      if (line.trim() == pathToAdd) {
        alreadyExists = true;
        break;
      }
    }

    if (alreadyExists) {
      return;
    }

    logger
      ..spacer
      ..info(
        'You should add the $kPackageName version directory "${cyan.wrap(pathToAdd)}" to .gitignore?',
      );

    if (ctx.isTest ||
        logger.confirm(
          'Would you like to do that now?',
        )) {
      // Add the new path if it doesn't exist.
      lines.add('');
      lines.add('# FVM Version Cache');
      lines.add(pathToAdd);
      project.gitignoreFile.writeAsStringSync('${lines.join('\n')}\n');
      logger
        ..spacer
        ..complete('Added $pathToAdd to .gitignore')
        ..spacer;
    }
  }

  /// Updates the link to make sure its always correct
  void updateFlutterSdkReference(Project project) {
    // Ensure the config link and symlink are updated
    final sdkVersion = project.pinnedVersion;
    if (sdkVersion == null) {
      throw AppException(
          'Cannot update link of project without a Flutter SDK version');
    }

    final sdkVersionDir = CacheService.instance.getVersionCacheDir(sdkVersion);

    // Clean up pre 3.0 links
    if (project.legacyCacheVersionSymlink.existsSync()) {
      project.legacyCacheVersionSymlink.deleteSync();
    }

    if (project.fvmCacheDir.existsSync()) {
      project.fvmCacheDir.deleteSync(recursive: true);
      project.fvmCacheDir.createSync(recursive: true);
    }

    createLink(
      project.cacheVersionSymlink,
      sdkVersionDir,
    );
  }

  /// Search for version configured
  Future<String?> findVersion() async {
    final project = await findAncestor();
    return project.pinnedVersion;
  }

  void updateVsCodeConfig(
    Project project,
  ) {
    final vscodeDir = Directory(join(
      project.projectDir.path,
      '.vscode',
    ));

    final vsCodeSettingsFile = File(join(
      vscodeDir.path,
      'settings.json',
    ));

    if (!vscodeDir.existsSync()) {
      return;
    }

    Map<String, dynamic> recommendedSettings = {
      'search.exclude': {'**/.fvm/versions': true},
      'files.watcherExclude': {'**/.fvm/versions': true},
      'files.exclude': {'**/.fvm/versions': true}
    };

    if (!vsCodeSettingsFile.existsSync()) {
      logger.detail('VSCode settings not found, to update.');
      vsCodeSettingsFile.createSync(recursive: true);
    }

    Map<String, dynamic> currentSettings = {};

    // Check if settings.json exists; if not, create it.
    if (vsCodeSettingsFile.existsSync()) {
      String contents = vsCodeSettingsFile.readAsStringSync();
      final sanitizedContent = contents.replaceAll(RegExp(r'\/\/.*'), '');
      if (sanitizedContent.isNotEmpty) {
        currentSettings = json.decode(sanitizedContent);
      }
    } else {
      vsCodeSettingsFile.create(recursive: true);
    }

    bool isUpdated = false;

    recommendedSettings.forEach((key, value) {
      final recommendedValue = value as Map<String, dynamic>;

      if (currentSettings.containsKey(key)) {
        final currentValue = currentSettings[key] as Map<String, dynamic>;

        recommendedValue.forEach((key, value) {
          if (!currentValue.containsKey(key) || currentValue[key] != value) {
            currentValue[key] = value;
            isUpdated = true;
          }
        });
      } else {
        currentSettings[key] = value;
        isUpdated = true;
      }
    });

    // Write updated settings back to settings.json
    if (isUpdated) {
      logger.complete(
        'VSCode $kPackageName settings has been updated. with correct exclude settings\n',
      );
    }

    final relativePath = relative(
      project.cacheVersionSymlinkCompat.path,
      from: project.projectDir.path,
    );

    currentSettings["dart.flutterSdkPath"] = relativePath;

    vsCodeSettingsFile.writeAsStringSync(prettyJson(currentSettings));
  }

  /// Recursive look up to find nested project directory
  /// Can start at a specific [directory] if provided
  Future<Project> findAncestor({Directory? directory}) async {
    // Get directory, defined root or current
    directory ??= Directory(ctx.workingDirectory);

    // Checks if the directory is root
    final isRootDir = rootPrefix(directory.path) == directory.path;

    // Gets project from directory
    final project = await loadByDirectory(directory);

    // If project has a config return it
    if (project.hasConfig) return project;

    // Return working directory if has reached root
    if (isRootDir) return loadByDirectory(Directory(ctx.workingDirectory));

    return await findAncestor(directory: directory.parent);
  }
}
