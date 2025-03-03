import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:io/ansi.dart';

import '../models/project_model.dart';
import '../utils/constants.dart';
import 'workflow.dart';

/// Manages the .gitignore file for FVM projects.
///
/// Handles adding the necessary entries to ignore the FVM version cache directory
/// in git repositories. Provides interactive and non-interactive options to update
/// the .gitignore file.
class SetupGitIgnoreWorkflow extends Workflow {
  /// The path pattern to add to the .gitignore file.
  ///
  /// Uses the [kFvmDirName] constant from constants.dart to ensure consistency.
  static const String kFvmPathToAdd = '$kFvmDirName/';

  /// The heading to add before the FVM entries in the .gitignore file.
  ///
  /// This helps users understand why these entries are present.
  static const String kGitIgnoreHeading = '# FVM Version Cache';

  /// Creates a new [SetupGitIgnoreWorkflow] with the provided context.
  SetupGitIgnoreWorkflow(super.context);

  /// Updates the project's .gitignore file to include FVM-specific entries.
  ///
  /// Adds [kFvmPathToAdd] to the project's .gitignore file if it doesn't already
  /// exist. Removes any older FVM-related entries before adding the new ones.
  ///
  /// If [updateGitIgnore] is disabled in the project config, this operation is skipped.
  ///
  /// When [force] is true, skips the confirmation prompt and applies the changes
  /// automatically. Otherwise, prompts the user for confirmation before modifying
  /// the file.
  ///
  /// Returns `true` if the operation was successful or if no action was needed,
  /// and `false` if an error occurred during file operations.
  Future<bool> call(Project project, {required bool force}) async {
    logger.detail('Checking .gitignore');

    // Check if gitignore management is enabled for this project
    final updateGitIgnore = project.config?.updateGitIgnore ?? true;
    logger.detail('Update gitignore: $updateGitIgnore');

    if (!updateGitIgnore) {
      logger.detail(
        '$kPackageName does not manage .gitignore for this project.',
      );

      return true;
    }

    final ignoreFile = project.gitIgnoreFile;
    bool isGitRepo = false;

    // Safely check if this is a git repository
    try {
      isGitRepo = await GitDir.isGitDir(project.path);
    } catch (e) {
      logger.warn('Failed to check git repository status: $e');
      isGitRepo = false;
    }

    // Create the .gitignore file if it doesn't exist
    if (!ignoreFile.existsSync()) {
      if (!isGitRepo) {
        logger.warn(
          'Project is not a git repository. \n But will set .gitignore as IDEs may use it,'
          'to determine what to index and display on searches.',
        );
      }

      try {
        ignoreFile.createSync(recursive: true);
      } catch (e) {
        logger.err('Failed to create .gitignore file: $e');

        return false;
      }
    }

    // Read the current content of the .gitignore file
    List<String> lines;
    try {
      lines = ignoreFile.readAsLinesSync();
    } catch (e) {
      logger.err('Failed to read .gitignore file: $e');

      return false;
    }

    // Check if the entry already exists
    if (lines.any((line) => line.trim() == kFvmPathToAdd)) {
      logger.detail('$kFvmPathToAdd already exists in .gitignore');

      return true;
    }

    // Remove any existing FVM-related entries
    lines = lines
        .where((line) =>
            !line.startsWith(kFvmDirName) && line.trim() != kGitIgnoreHeading)
        .toList();

    // Append the correct line at the end
    lines.addAll(['', kGitIgnoreHeading, kFvmPathToAdd]);

    // Remove any consecutive blank lines to keep the file clean
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
      'You should add the $kPackageName version directory "${cyan.wrap(kFvmPathToAdd)}" to .gitignore.',
    );

    // Handle force flag or ask for confirmation
    if (force) {
      logger.warn(
        'Skipping .gitignore confirmation because of --force flag detected',
      );
    } else {
      final confirmation =
          logger.confirm('Would you like to do that now?', defaultValue: true);

      if (!confirmation) {
        return false;
      }
    }

    // Write the updated content to the .gitignore file
    try {
      ignoreFile.writeAsStringSync(lines.join('\n'), mode: FileMode.write);
      logger.success(
        'Added $kFvmPathToAdd to .gitignore ${force ? '(forced)' : ''}',
      );

      return true;
    } catch (e) {
      logger.err('Failed to update .gitignore file: $e');

      return false;
    }
  }
}
