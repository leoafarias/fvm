import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:jsonc/jsonc.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../models/cache_flutter_version_model.dart';
import '../models/project_model.dart';
import '../services/logger_service.dart';
import '../utils/constants.dart';
import '../utils/context.dart';
import '../utils/convert_posix_path.dart';
import '../utils/exceptions.dart';
import '../utils/extensions.dart';
import '../utils/helpers.dart';
import '../utils/pretty_json.dart';
import '../utils/which.dart';
import 'resolve_dependencies.workflow.dart';
import 'setup_flutter.workflow.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow({
  required CacheFlutterVersion version,
  required Project project,
  bool force = false,
  bool skipSetup = false,
  bool runPubGetOnSdkChange = true,
  String? flavor,
  required FvmController controller,
}) async {
  // If project use check that is Flutter project
  if (!project.hasPubspec && !force) {
    if (project.hasConfig) {
      if (project.path != controller.context.workingDirectory) {
        controller.logger
          ..spacer
          ..info('Using $kFvmConfigFileName in ${project.path}')
          ..spacer
          ..info(
            'If this is incorrect either use the --force flag or remove the $kFvmConfigFileName and the $kFvmDirName directory.',
          )
          ..spacer;
      }
    } else {
      controller.logger
        ..spacer
        ..info('No pubspec.yaml detected in this directory');
      final proceed = controller.logger.confirm(
        'Would you like to continue?',
        defaultValue: true,
      );

      if (!proceed) exit(ExitCode.success.code);
    }
  }

  controller.logger
    ..detail('')
    ..detail('Updating project config')
    ..detail('Project name: ${project.name}')
    ..detail('Project path: ${project.path}')
    ..detail('');

  if (!skipSetup && version.isNotSetup) {
    await setupFlutterWorkflow(version, controller: controller);
  }

  // Checks if the project constraints are met
  _checkProjectVersionConstraints(
    project,
    version,
    force: force,
    logger: controller.logger,
  );

  final updatedProject = controller.projectService.update(
    project,
    flavors: {if (flavor != null) flavor: version.name},
    flutterSdkVersion: version.name,
  );

  await _checkGitignore(updatedProject, force: force, controller: controller);

  if (runPubGetOnSdkChange) {
    await resolveDependenciesWorkflow(
      updatedProject,
      version,
      force: force,
      controller: controller,
    );
  }

  _updateLocalSdkReference(updatedProject, version, controller: controller);
  _updateCurrentSdkReference(updatedProject, version, controller: controller);

  _manageVsCodeSettings(updatedProject, controller: controller);

  final versionLabel = cyan.wrap(version.printFriendlyName);
  // Different message if configured environment
  if (flavor != null) {
    controller.logger.success(
      'Project now uses Flutter SDK: $versionLabel on [$flavor] flavor.',
    );
  } else {
    controller.logger.success('Project now uses Flutter SDK : $versionLabel');
  }

  if (version.flutterExec == which('flutter')) {
    controller.logger.detail('Flutter SDK is already in your PATH');

    return;
  }

  if (isVsCode()) {
    controller.logger
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
Future<void> _checkGitignore(
  Project project, {
  required bool force,
  required FvmController controller,
}) async {
  controller.logger.detail('Checking .gitignore');

  final updateGitIgnore = project.config?.updateGitIgnore ?? true;

  controller.logger.detail('Update gitignore: $updateGitIgnore');

  if (!updateGitIgnore) {
    controller.logger.detail(
      '$kPackageName does not manage .gitignore for this project.',
    );

    return;
  }

  final pathToAdd = '.fvm/';
  final heading = '# FVM Version Cache';
  final ignoreFile = project.gitIgnoreFile;

  if (!ignoreFile.existsSync()) {
    if (!await GitDir.isGitDir(project.path)) {
      controller.logger.warn(
        'Project is not a git repository. \n But will set .gitignore as IDEs may use it,'
        'to determine what to index and display on searches,',
      );
    }
    ignoreFile.createSync(recursive: true);
  }

  List<String> lines = ignoreFile.readAsLinesSync();

  if (lines.any((line) => line.trim() == pathToAdd)) {
    controller.logger.detail('$pathToAdd already exists in .gitignore');

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

  controller.logger.info(
    'You should add the $kPackageName version directory "${cyan.wrap(pathToAdd)}" to .gitignore.',
  );

  if (force) {
    controller.logger.warn(
      'Skipping .gitignore confirmation because of --force flag detected',
    );

    return;
  }

  if (controller.logger.confirm(
    'Would you like to do that now?',
    defaultValue: true,
  )) {
    ignoreFile.writeAsStringSync(lines.join('\n'), mode: FileMode.write);
    controller.logger
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
  CacheFlutterVersion cachedVersion, {
  required bool force,
  required Logger logger,
}) {
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

    final message =
        '${cachedVersion.printFriendlyName} has Dart SDK $sdkVersion';

    if (!allowedInConstraint) {
      logger
        ..info(
          '$message does not meet the project constraints of $constraints.',
        )
        ..info('This could cause unexpected behavior or issues.')
        ..info('');

      if (force) {
        logger.warn(
          'Skipping version constraint confirmation because of --force flag detected',
        );

        return;
      }

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
void _updateLocalSdkReference(
  Project project,
  CacheFlutterVersion version, {
  required FvmController controller,
}) {
  if (project.localFvmPath.file.existsSync()) {
    project.localFvmPath.file.createSync(recursive: true);
  }

  final sdkVersionFile = p.join(project.localFvmPath, 'version');
  final releaseFile = p.join(project.localFvmPath, 'release');

  sdkVersionFile.file.write(project.dartToolVersion ?? '');
  releaseFile.file.write(version.name);

  if (!controller.context.privilegedAccess) return;

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
void _updateCurrentSdkReference(
  Project project,
  CacheFlutterVersion version, {
  required FvmController controller,
}) {
  final currentSdkLink = p.join(project.localFvmPath, 'flutter_sdk');

  if (currentSdkLink.link.existsSync()) {
    currentSdkLink.link.deleteSync();
  }

  if (!controller.context.privilegedAccess) return;

  currentSdkLink.link.createLink(version.directory);
}

/// Updates VS Code configuration for the project
///
/// This method updates the VS Code configuration for the provided [project].
/// It sets the correct exclude settings in the VS Code settings file to exclude
/// the .fvm/versions directory from search and file watchers.///
/// The method also updates the "dart.flutterSdkPath" setting to use the relative
/// path of the .fvm symlink.
void _manageVsCodeSettings(
  Project project, {
  required FvmController controller,
}) {
  final updateVscodeSettings = project.config?.updateVscodeSettings ?? true;

  final vscodeDir = Directory(p.join(project.path, '.vscode'));
  final vscodeSettingsFile = File(p.join(vscodeDir.path, 'settings.json'));

  final isUsingVscode = isVsCode() || vscodeDir.existsSync();

  if (!updateVscodeSettings) {
    controller.logger.detail(
      '$kPackageName does not manage $kVsCode settings for this project.',
    );

    if (isUsingVscode) {
      controller.logger.warn(
        'You are using $kVsCode, but $kPackageName is '
        'not managing $kVsCode settings for this project.'
        'Please remove "updateVscodeSettings: false" from $kFvmConfigFileName',
      );
    }

    return;
  }

  if (!isUsingVscode) {
    return;
  }

  if (!vscodeSettingsFile.existsSync()) {
    controller.logger.detail('$kVsCode settings not found, to update.');
    vscodeSettingsFile.createSync(recursive: true);
  }

  Map<String, dynamic> currentSettings = {};

  // Check if settings.json exists; if not, create it.
  if (vscodeSettingsFile.existsSync()) {
    try {
      String contents = vscodeSettingsFile.readAsStringSync();

      if (contents.isNotEmpty) {
        currentSettings = jsonc.decode(contents);
      }
    } on FormatException catch (err, stackTrace) {
      final relativePath = p.relative(
        vscodeSettingsFile.path,
        from: controller.context.workingDirectory,
      );

      Error.throwWithStackTrace(
        AppDetailedException(
          'Error parsing $kVsCode settings at $relativePath',
          'Please use a tool like https://jsonlint.com to validate and fix it\n $err',
        ),
        stackTrace,
      );
    }
  } else {
    vscodeSettingsFile.create(recursive: true);
  }

  if (controller.context.privilegedAccess) {
    final relativePath = p.relative(
      project.localVersionSymlinkPath,
      from: project.path,
    );

    currentSettings["dart.flutterSdkPath"] = convertToPosixPath(relativePath);
  } else {
    currentSettings["dart.flutterSdkPath"] = project.localVersionSymlinkPath;
  }

  vscodeSettingsFile.writeAsStringSync(prettyJson(currentSettings));
}
