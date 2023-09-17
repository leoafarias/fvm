import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/config_repository.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_semver/pub_semver.dart';

/// Pin version to the project
void updateSdkVersionWorkflow(
  Project project,
  CacheFlutterVersion version, {
  String? flavor,
}) {
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

    ProjectService.instance.updateFlutterSdkReference(project);
    ProjectService.instance.updateVsCodeConfig(project);
    logger.detail('Project config updated');

    _addToGitignore(project, '.fvm/versions');
  } catch (e) {
    logger.fail('Failed to update project config: $e');
    rethrow;
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
void _addToGitignore(Project project, String pathToAdd) {
  bool alreadyExists = false;
  final ignoreFile = project.gitignoreFile;

  // Check if .gitignore exists, and if not, create it.
  if (!ignoreFile.existsSync()) {
    ignoreFile.createSync();
  }

  // Read existing lines.
  List<String> lines = ignoreFile.readAsLinesSync();

  // Check if path already exists in .gitignore
  for (var line in lines) {
    if (line.trim() == pathToAdd) {
      alreadyExists = true;
      break;
    }
  }

  if (alreadyExists) return;

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
    ignoreFile.writeAsStringSync('${lines.join('\n')}\n');
    logger
      ..spacer
      ..complete('Added $pathToAdd to .gitignore')
      ..spacer;
  }
}

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
