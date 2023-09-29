import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/io_utils.dart';
import 'package:fvm/src/utils/pretty_json.dart';
import 'package:fvm/src/utils/which.dart';
import 'package:fvm/src/workflows/setup_flutter_workflow.dart';
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
  bool unprivileged = false,
  String? flavor,
}) async {
  // If project use check that is Flutter project
  if (!project.isFlutter && !force) {
    logger
      ..spacer
      ..info(
        'This does not seem to be a Flutter project directory',
      );
    final proceed = logger.confirm(
      'Would you like to continue?',
    );

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

  // Attach as main version if no flavor is set
  final flavors = <String, String>{
    if (flavor != null) flavor: version.name,
  };

  final updatedProject = ProjectService.fromContext.update(
    project,
    flavors: flavors,
    flutterSdkVersion: version.name,
  );

  _updateLocalSdkReference(
    updatedProject,
    version,
    priviledged: !unprivileged,
  );

  _checkGitignore(updatedProject);

  await resolveDependenciesWorkflow(
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
    logger.success(
      'Project now uses Flutter SDK : $versionLabel',
    );
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

  return;
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
  if (!await GitDir.isGitDir(project.path)) {
    return;
  }

  final pathToAdd = '.fvm';
  final ignoreFile = project.gitignoreFile;

  if (!ignoreFile.existsSync()) {
    ignoreFile.createSync(recursive: true);
  }

  final lines = ignoreFile.readAsLinesSync();

  if (lines.any((line) => line.trim() == pathToAdd)) {
    return;
  }

  logger
    ..spacer
    ..info(
      'You should add the $kPackageName version directory "${cyan.wrap(pathToAdd)}" to .gitignore?',
    );

  if (logger.confirm(
    'Would you like to do that now?',
    defaultValue: true,
  )) {
    // If pathToAdd not found, append it to the file

    ignoreFile.writeAsStringSync(
      '\n# FVM Version Cache\n$pathToAdd\n',
      mode: FileMode.append,
    );
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
  final sdkVersion = cachedVersion.flutterSdkVersion;
  final constraints = project.sdkConstraint;

  if (sdkVersion != null && constraints != null) {
    final allowedInConstraint = constraints.allows(Version.parse(sdkVersion));

    final message = cachedVersion.isRelease
        ? 'Version: ${cachedVersion.name}.'
        : '${cachedVersion.printFriendlyName} has SDK $sdkVersion';

    if (!allowedInConstraint) {
      logger.notice('Flutter SDK does not meet project constraints');

      logger
        ..info(
            '$message does not meet the project constraints of $constraints.')
        ..info('This could cause unexpected behavior or issues.')
        ..spacer;

      if (!logger.confirm(
        'Would you like to proceed?',
        defaultValue: true,
      )) {
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
  required bool priviledged,
}) {
// Legacy link for fvm < 3.0.0
  final legacyLink = Link(join(
    project.localVersionsCachePath,
    'flutter_sdk',
  ));

  // Clean up pre 3.0 links
  if (legacyLink.existsSync()) {
    legacyLink.deleteSync();
  }

  final localVersionsCache = Directory(project.localVersionsCachePath);

  if (localVersionsCache.existsSync()) {
    localVersionsCache.deleteSync(recursive: true);
  }
  localVersionsCache.createSync(recursive: true);

  final sdkVersionFile = File(join(project.localFvmPath, 'version'));
  final releaseFile = File(join(project.localFvmPath, 'release'));

  sdkVersionFile.writeAsStringSync(project.dartToolVersion ?? '');
  releaseFile.writeAsStringSync(version.name);

  if (priviledged) {
    createLink(
      project.localVersionSymlinkPath,
      version.directory,
    );
  }
}

/// Updates VS Code configuration for the project
///
/// This method updates the VS Code configuration for the provided [project].
/// It sets the correct exclude settings in the VS Code settings file to exclude
/// the .fvm/versions directory from search and file watchers.
///
/// The method also updates the "dart.flutterSdkPath" setting to use the relative
/// path of the .fvm symlink.
void _manageVscodeSettings(Project project) {
  if (project.config?.unmanagedVscode == false) {
    logger.detail(
      '$kPackageName does not manage VSCode settings for this project.',
    );
    return;
  }

  final vscodeDir = Directory(join(project.path, '.vscode'));
  final vscodeSettingsFile = File(join(vscodeDir.path, 'settings.json'));

  final donotManageVscode = project.config?.unmanagedVscode == true;
  final isUsingVscode = isVsCode() || vscodeDir.existsSync();

  if (donotManageVscode) {
    logger.detail(
      '$kPackageName does not manage $kVsCode settings for this project.',
    );

    if (isUsingVscode) {
      logger
        ..warn(
          'You are using $kVsCode, but $kPackageName is ',
        )
        ..warn(
          'not managing $kVsCode settings for this project.',
        )
        ..warn('Please remove "unmanagedVscode" from $kFvmConfigFileName');
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
        unmanagedVscode: true,
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

  final relativePath = relative(
    project.localVersionSymlinkPath,
    from: project.path,
  );

  currentSettings["dart.flutterSdkPath"] = relativePath;

  vscodeSettingsFile.writeAsStringSync(prettyJson(currentSettings));
}
