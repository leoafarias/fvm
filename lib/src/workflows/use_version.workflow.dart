import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/pretty_json.dart';
import 'package:fvm/src/utils/which.dart';
import 'package:fvm/src/workflows/resolve_dependencies.workflow.dart';
import 'package:fvm/src/workflows/setup_flutter.workflow.dart';
import 'package:git/git.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

import '../services/logger_service.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow({
  required CacheFlutterVersion version,
  required Project project,
  bool force = false,
  bool skipSetup = false,
  String? flavor,
}) async {
  // If project use check that is Flutter project
  if (!project.isFlutter && !force) {
    logger
      ..spacer
      ..info('This does not seem to be a Flutter project directory');
    final proceed = logger.confirm('Would you like to continue?');

    if (!proceed) exit(ExitCode.success.code);
  }

  logger
    ..detail('')
    ..detail('Updating project config')
    ..detail('Project name: ${project.name}')
    ..detail('Project path: ${project.path}')
    ..detail('');

  if (!skipSetup && version.notSetup) {
    await setupFlutterWorkflow(version);
  }

  // Checks if the project constraints are met
  _checkProjectVersionConstraints(project, version);

  final updatedProject = ProjectService.fromContext.update(
    project,
    flavors: {if (flavor != null) flavor: version.name},
    flutterSdkVersion: version.name,
  );

  await _checkGitignore(updatedProject);

  await resolveDependenciesWorkflow(updatedProject, version);

  _updateLocalSdkReference(updatedProject, version);
  _updateCurrentSdkReference(
    updatedProject,
    version,
  );

  _manageVscodeSettings(updatedProject);

  final versionLabel = cyan.wrap(version.printFriendlyName);
  // Different message if configured environment
  if (flavor != null) {
    logger.success(
      'Project now uses Flutter SDK: $versionLabel on [$flavor] flavor.',
    );
  } else {
    logger.success('Project now uses Flutter SDK : $versionLabel');
  }

  if (version.flutterExec == which('flutter')) {
    logger.detail('Flutter SDK is already in your PATH');
    return;
  }

  if (isVsCode()) {
    logger
      ..important(
        'Running on VsCode, please restart the terminal to apply changes.',
      )
      ..info('You can then use "flutter" command within the VsCode terminal.');
  }
}

/// Adds to .gitignore paths that should be ignored for fvm
///
/// This method adds the given [pathToAdd] to the .gitignore file of the provided [project].
/// If the .gitignore file doesn't exist, it will be created. The method checks if
/// the given path already exists in the .gitignore file before adding it.
///
/// The method prompts the user for confirmation before actually adding the path,
/// unless running in a test environment.
Future<void> _checkGitignore(Project project) async {
  logger.detail('Checking .gitignore');

  final updateGitIgnore = project.config?.updateGitIgnore ?? true;

  logger.detail('Update gitignore: $updateGitIgnore');
  if (!await GitDir.isGitDir(project.path)) {
    logger.detail('Project is not a git repository.');
    return;
  }

  if (!updateGitIgnore) {
    logger.detail(
      '$kPackageName does not manage .gitignore for this project.',
    );
    return;
  }

  final pathToAdd = '.fvm/';
  final heading = '# FVM Version Cache';
  final ignoreFile = project.gitignoreFile;

  if (!ignoreFile.existsSync()) {
    ignoreFile.createSync(recursive: true);
  }

  List<String> lines = ignoreFile.readAsLinesSync();

  if (lines.any((line) => line.trim() == pathToAdd)) {
    logger.detail('$pathToAdd already exists in .gitignore');
    return;
  }

  lines = lines
      .where((line) => !line.startsWith('.fvm') && line.trim() != heading)
      .toList();

  // Append the correct line at the end
  lines.addAll(['', heading, pathToAdd]);

  // Remove any lines that have consecutive blank lines.
  lines = lines.fold<List<String>>([], (previousValue, element) {
    if (previousValue.isEmpty) {
      previousValue.add(element);
    } else {
      final lastLine = previousValue.last;
      if (lastLine.trim().isEmpty && element.trim().isEmpty) {
        return previousValue;
      }
      previousValue.add(element);
    }
    return previousValue;
  });

  logger.info(
    'You should add the $kPackageName version directory "${cyan.wrap(pathToAdd)}" to .gitignore?',
  );

  if (logger.confirm('Would you like to do that now?', defaultValue: true)) {
    ignoreFile.writeAsStringSync(lines.join('\n'), mode: FileMode.write);
    logger
      ..success('Added $pathToAdd to .gitignore')
      ..spacer;
  }
}

/// Checks if the Flutter SDK version used in the project meets the specified constraints.
///
/// The [project] parameter represents the project being checked, while the [cachedVersion]
/// parameter is the cached version of the Flutter SDK.
void _checkProjectVersionConstraints(
  Project project,
  CacheFlutterVersion cachedVersion,
) {
  final sdkVersion = cachedVersion.dartSdkVersion;
  final constraints = project.sdkConstraint;

  if (sdkVersion != null &&
      constraints != null &&
      !constraints.isEmpty &&
      sdkVersion.isNotEmpty) {
    Version dartSdkVersion;

    try {
      dartSdkVersion = Version.parse(sdkVersion);
    } on FormatException {
      logger.warn('Could not parse Flutter SDK version $sdkVersion');

      return;
    }

    final allowedInConstraint = constraints.allows(dartSdkVersion);

    final message = cachedVersion.isRelease
        ? 'Version: ${cachedVersion.name}.'
        : '${cachedVersion.printFriendlyName} has SDK $sdkVersion';

    if (!allowedInConstraint) {
      logger.notice('Flutter SDK does not meet project constraints');

      logger
        ..info(
          '$message does not meet the project constraints of $constraints.',
        )
        ..info('This could cause unexpected behavior or issues.')
        ..spacer;

      if (!logger.confirm('Would you like to proceed?', defaultValue: true)) {
        throw AppException(
          'The Flutter SDK version $sdkVersion is not compatible with the project constraints. You may need to adjust the version to avoid potential issues.',
        );
      }
    }
  }
}

/// Updates the link to make sure its always correct
///
/// This method updates the .fvm symlink in the provided [project] to point to the cache
/// directory of the currently pinned Flutter SDK version. It also cleans up legacy links
/// that are no longer needed.
///
/// Throws an [AppException] if the project doesn't have a pinned Flutter SDK version.
void _updateLocalSdkReference(Project project, CacheFlutterVersion version) {
  if (project.localFvmPath.file.existsSync()) {
    project.localFvmPath.file.createSync(recursive: true);
  }

  final sdkVersionFile = join(project.localFvmPath, 'version');
  final releaseFile = join(project.localFvmPath, 'release');

  sdkVersionFile.file.write(project.dartToolVersion ?? '');
  releaseFile.file.write(version.name);

  if (!ctx.priviledgedAccess) return;

  project.localVersionsCachePath.dir
    ..deleteIfExists()
    ..createSync(recursive: true);

  project.localVersionSymlinkPath.link.createLink(version.directory);
}

/// Updates the `flutter_sdk` link to ensure it always points to the pinned SDK version.
///
/// This is required for Android Studio to work with different Flutter SDK versions.
///
/// Throws an [AppException] if the project doesn't have a pinned Flutter SDK version.
void _updateCurrentSdkReference(Project project, CacheFlutterVersion version) {
  final currentSdkLink = join(project.localFvmPath, 'flutter_sdk');

  if (currentSdkLink.link.existsSync()) {
    currentSdkLink.link.deleteSync();
  }

  if (!ctx.priviledgedAccess) return;

  currentSdkLink.link.createLink(version.directory);
}

/// Updates VS Code configuration for the project
///
/// This method updates the VS Code configuration for the provided [project].
/// It sets the correct exclude settings in the VS Code settings file to exclude
/// the .fvm/versions directory from search and file watchers.///
/// The method also updates the "dart.flutterSdkPath" setting to use the relative
/// path of the .fvm symlink.
void _manageVscodeSettings(Project project) {
  final updateVscodeSettings = project.config?.updateVscodeSettings ?? true;

  final vscodeDir = Directory(join(project.path, '.vscode'));
  final vscodeSettingsFile = File(join(vscodeDir.path, 'settings.json'));

  final isUsingVscode = isVsCode() || vscodeDir.existsSync();

  if (!updateVscodeSettings) {
    logger.detail(
      '$kPackageName does not manage $kVsCode settings for this project.',
    );

    if (isUsingVscode) {
      logger.warn(
        'You are using $kVsCode, but $kPackageName is '
        'not managing $kVsCode settings for this project.'
        'Please remove "updateVscodeSettings: false" from $kFvmConfigFileName',
      );
    }
    return;
  }

  if (!isUsingVscode) {
    final confirmation = logger.confirm(
      'Are you using $kVsCode for this project?',
    );

    if (!confirmation) {
      ProjectService.fromContext.update(
        project,
        updateVscodeSettings: false,
      );
      return;
    }
  }

  if (!vscodeSettingsFile.existsSync()) {
    logger.detail('$kVsCode settings not found, to update.');
    vscodeSettingsFile.createSync(recursive: true);
  }

  Map<String, dynamic> currentSettings = {};

  // Check if settings.json exists; if not, create it.
  if (vscodeSettingsFile.existsSync()) {
    try {
      String contents = vscodeSettingsFile.readAsStringSync();
      final sanitizedContent = contents.replaceAll(RegExp(r'\/\/.*'), '');
      if (sanitizedContent.isNotEmpty) {
        currentSettings = json.decode(sanitizedContent);
      }
    } on FormatException {
      final relativePath = relative(
        vscodeSettingsFile.path,
        from: ctx.workingDirectory,
      );
      throw AppDetailedException(
        'Error parsing $kVsCode settings at $relativePath',
        'Please use a tool like https://jsonformatter.curiousconcept.com to validate and fix it',
      );
    }
  } else {
    vscodeSettingsFile.create(recursive: true);
  }

  if (ctx.priviledgedAccess) {
    final relativePath = relative(
      project.localVersionSymlinkPath,
      from: project.path,
    );

    currentSettings["dart.flutterSdkPath"] = relativePath;
  } else {
    currentSettings["dart.flutterSdkPath"] = project.localVersionSymlinkPath;
  }

  vscodeSettingsFile.writeAsStringSync(prettyJson(currentSettings));
}
