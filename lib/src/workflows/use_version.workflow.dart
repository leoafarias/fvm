import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/io_utils.dart';
import 'package:fvm/src/utils/pretty_json.dart';
import 'package:fvm/src/utils/which.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

import '../utils/logger.dart';

/// Checks if version is installed, and installs or exits
Future<void> useVersionWorkflow({
  required CacheFlutterVersion version,
  required Project project,
  bool force = false,
  String? flavor,
}) async {
  // If project use check that is Flutter project
  if (!project.isFlutter && !force) {
    final proceed = logger.confirm(
      'You are running "use" on a project that does not use Flutter. Would you like to continue?',
    );

    if (!proceed) exit(ExitCode.success.code);
  }

  logger
    ..detail('')
    ..detail('Updating project config')
    ..detail('Project name: ${project.name}')
    ..detail('Project path: ${project.path}')
    ..detail('');

  // Checks if the project constraints are met
  _checkProjectVersionConstraints(project, version);

  try {
    final newConfig = project.config ?? ConfigDto.empty();

    // Attach as main version if no flavor is set
    final flavors = newConfig.flavors ?? {};

    if (flavor != null) {
      flavors[flavor] = version;
    }

    final mergedConfig = newConfig.copyWith(
      flutterSdkVersion: version.name,
      flavors: flavors,
    );

    ConfigRepository(project.configPath).save(mergedConfig);

    // Clean this up
    project.config = mergedConfig;

    _updateFlutterSdkReference(project);
    _ensureVscodeSettings(project);
    logger.detail('Project config updated');

    _ensureGitIgnore(project, '.fvm/versions');
  } catch (e) {
    logger.fail('Failed to update project config: $e');
    rethrow;
  }

  final versionLabel = cyan.wrap(version.printFriendlyName);
  // Different message if configured environment
  if (flavor != null) {
    logger.complete(
      'Project now uses Flutter SDK: $versionLabel on [$flavor] flavor.',
    );
  } else {
    logger.complete(
      'Project now uses Flutter SDK : $versionLabel',
    );
  }

  if (version.flutterExec == which('flutter')) {
    logger.detail('Flutter SDK is already in your PATH');
    return;
  }

  if (isVsCode()) {
    logger
      ..spacer
      ..notice(
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
Future<void> _ensureGitIgnore(Project project, String pathToAdd) async {
  final ignoreFile = project.gitignoreFile;

  // Create .gitignore if it doesn't exist
  if (!ignoreFile.existsSync()) {
    ignoreFile.createSync();
  }

  final fileContents = ignoreFile.openRead();
  final lines = utf8.decoder.bind(fileContents).transform(LineSplitter());

  bool alreadyExists = false;

// Append the new line to the .gitignore file
  void appendPathToGitignore() {
    logger
      ..spacer
      ..info(
        'You should add the $kPackageName version directory "${cyan.wrap(pathToAdd)}" to .gitignore?',
      );

    if (ctx.isTest || logger.confirm('Would you like to do that now?')) {
      // Append the new line
      ignoreFile.writeAsStringSync('\n# FVM Version Cache\n$pathToAdd\n',
          mode: FileMode.append);

      logger
        ..spacer
        ..complete('Added $pathToAdd to .gitignore')
        ..spacer;
    }
  }

  final completer = Completer();

  // Check if pathToAdd exists in a line
  void onListen(String line) {
    if (line.trim() != pathToAdd) return;
    // If it does, set alreadyExists to true
    alreadyExists = true;
  }

  void onError(error) {
    logger.err("An error occurred while reading the .gitignore file");
    completer.completeError(error);
  }

  void onDone() {
    if (!alreadyExists) {
      appendPathToGitignore();
    }

    completer.complete();
  }

  // Read lines, and check if pathToAdd exists
  lines.listen(onListen, onDone: onDone, onError: onError);

  await completer.future;
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

    final releaseMessage =
        'Flutter SDK version ${cachedVersion.name} does not meet the project constraints.';
    final notReleaseMessage =
        'Flutter SDK: ${cachedVersion.name} $sdkVersion is not allowed in the project constraints.';
    final message =
        cachedVersion.isRelease ? releaseMessage : notReleaseMessage;

    if (!allowedInConstraint) {
      logger.notice(message);

      if (!logger.confirm('Would you like to continue?')) {
        throw AppException(
          'Version $sdkVersion is not allowed in the project constraints',
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
void _updateFlutterSdkReference(Project project) {
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

  if (project.fvmCachePath.existsSync()) {
    project.fvmCachePath.deleteSync(recursive: true);
  }
  project.fvmCachePath.createSync(recursive: true);

  createLink(
    project.cacheVersionSymlink,
    sdkVersionDir,
  );
}

/// Updates VS Code configuration for the project
///
/// This method updates the VS Code configuration for the provided [project].
/// It sets the correct exclude settings in the VS Code settings file to exclude
/// the .fvm/versions directory from search and file watchers.
///
/// The method also updates the "dart.flutterSdkPath" setting to use the relative
/// path of the .fvm symlink.
void _ensureVscodeSettings(
  Project project,
) {
  final vscodeDir = Directory(join(
    project.path,
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

  for (var entry in recommendedSettings.entries) {
    final recommendedValue = entry.value as Map<String, dynamic>;

    if (currentSettings.containsKey(entry.key)) {
      final currentValue = currentSettings[entry.key] as Map<String, dynamic>;

      for (var innerEntry in recommendedValue.entries) {
        if (currentValue[innerEntry.key] != innerEntry.value) {
          currentValue[innerEntry.key] = innerEntry.value;
          isUpdated = true;
        }
      }
    } else {
      currentSettings[entry.key] = recommendedValue;
      isUpdated = true;
    }
  }

  // Write updated settings back to settings.json
  if (isUpdated) {
    logger.complete(
      'VSCode $kPackageName settings has been updated. with correct exclude settings\n',
    );
  }

  final relativePath = relative(
    project.cacheVersionSymlinkCompat.path,
    from: project.path,
  );

  currentSettings["dart.flutterSdkPath"] = relativePath;

  vsCodeSettingsFile.writeAsStringSync(prettyJson(currentSettings));
}
