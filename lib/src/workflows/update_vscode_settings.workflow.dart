import 'dart:async';
import 'dart:io';

import 'package:jsonc/jsonc.dart';
import 'package:path/path.dart' as p;

import '../models/project_model.dart';
import '../utils/constants.dart';
import '../utils/convert_posix_path.dart';
import '../utils/helpers.dart';
import '../utils/pretty_json.dart';
import 'workflow.dart';

/// Manages VS Code settings for Flutter projects using FVM.
///
/// Configures VS Code settings in both folder settings (.vscode/settings.json)
/// and workspace settings (.code-workspace) to work with the FVM-managed Flutter SDK.
class UpdateVsCodeSettingsWorkflow extends Workflow {
  /// The typical extension for VS Code workspace files
  static const String kWorkspaceFileExt = '.code-workspace';

  /// Creates a new [UpdateVsCodeSettingsWorkflow] with the provided context.
  UpdateVsCodeSettingsWorkflow(super.context);

  /// Checks if the project has VS Code configuration files.
  bool _hasVsCodeFiles(Project project) {
    final vscodeDir = Directory(p.join(project.path, '.vscode'));

    return vscodeDir.existsSync();
  }

  /// Finds a VS Code workspace file in the project directory.
  ///
  /// Returns the most relevant workspace file or null if none is found.
  /// Prioritizes files containing the project name if available.
  File? _findWorkspaceFile(Project project) {
    try {
      final dirContents = Directory(project.path).listSync();
      final workspaceFiles = <File>[];

      // Collect all workspace files
      for (final entity in dirContents) {
        if (entity is File && entity.path.endsWith(kWorkspaceFileExt)) {
          workspaceFiles.add(entity);
        }
      }

      if (workspaceFiles.isEmpty) {
        return null;
      }

      // Log all found workspace files
      if (workspaceFiles.length > 1) {
        logger.detail('Found ${workspaceFiles.length} workspace files');
      } else {
        logger.detail(
          'Found workspace file: ${p.basename(workspaceFiles.first.path)}',
        );
      }

      // Prefer workspace files that might be related to the project
      final projectName = p.basename(project.path).toLowerCase();
      for (final file in workspaceFiles) {
        final fileName = p.basenameWithoutExtension(file.path).toLowerCase();
        if (fileName.contains(projectName) || projectName.contains(fileName)) {
          logger.detail('Selected workspace file: ${p.basename(file.path)}');

          return file;
        }
      }

      // Fall back to the first workspace file
      return workspaceFiles.first;
    } catch (e) {
      logger.detail('Error searching for workspace file: $e');

      return null;
    }
  }

  /// Updates the folder-level settings in .vscode/settings.json
  void _updateFolderSettings(Project project) {
    // Set up paths for VS Code settings
    final vscodeDir = Directory(p.join(project.path, '.vscode'));
    final vscodeSettingsFile = File(p.join(vscodeDir.path, 'settings.json'));

    // Check if project is using VS Code
    final isUsingVscode = isVsCode() || vscodeDir.existsSync();

    // If not using VS Code, no settings to update
    if (!isUsingVscode) {
      logger.detail(
        'Project is not using $kVsCode, skipping folder settings update.',
      );

      return;
    }

    // Create the settings file if it doesn't exist
    if (!vscodeSettingsFile.existsSync()) {
      logger.detail('$kVsCode settings not found, creating new settings file.');
      try {
        vscodeSettingsFile.createSync(recursive: true);
      } catch (e) {
        logger.err('Failed to create $kVsCode settings file: $e');

        return;
      }
    }

    // Read current settings
    Map<String, dynamic> currentSettings = {};
    try {
      String contents = vscodeSettingsFile.readAsStringSync();
      if (contents.isNotEmpty) {
        currentSettings = jsonc.decode(contents);
      }
    } on FormatException catch (_) {
      final relativePath = p.relative(
        vscodeSettingsFile.path,
        from: context.workingDirectory,
      );

      logger.err(
        'Error parsing $kVsCode settings at $relativePath\n'
        'Please use a tool like https://jsonlint.com to validate and fix it',
      );

      return;
    } catch (e) {
      logger.err('Failed to read $kVsCode settings: $e');

      return;
    }

    // Update Flutter SDK path setting
    try {
      if (context.privilegedAccess) {
        final relativePath = p.relative(
          project.localVersionSymlinkPath,
          from: project.path,
        );

        currentSettings["dart.flutterSdkPath"] =
            convertToPosixPath(relativePath);
      } else {
        currentSettings["dart.flutterSdkPath"] =
            project.localVersionSymlinkPath;
      }

      // Write updated settings back to file
      vscodeSettingsFile.writeAsStringSync(prettyJson(currentSettings));
      logger.success('Updated $kVsCode folder Flutter SDK path setting.');
    } catch (e) {
      logger.err('Failed to update $kVsCode folder settings: $e');
    }
  }

  /// Updates all found workspace files with the correct Flutter SDK path
  void _updateWorkspaceFiles(Project project) {
    final workspaceFile = _findWorkspaceFile(project);

    if (workspaceFile == null) {
      logger.detail('No $kVsCode workspace files found.');

      return;
    }

    try {
      // Read workspace file
      String contents = workspaceFile.readAsStringSync();
      Map<String, dynamic> workspaceSettings = {};

      if (contents.isNotEmpty) {
        try {
          workspaceSettings = jsonc.decode(contents);
        } on FormatException catch (_) {
          final relativePath = p.relative(
            workspaceFile.path,
            from: context.workingDirectory,
          );
          logger.err(
            'Error parsing workspace file at $relativePath\n'
            'Please use a tool like https://jsonlint.com to validate and fix it',
          );
        }
      }

      // Initialize settings section if it doesn't exist
      workspaceSettings['settings'] ??= <String, dynamic>{};

      // Get path to Flutter SDK
      final String sdkPath;
      if (context.privilegedAccess) {
        // For workspace files, calculate relative path from workspace file location
        final workspaceDir = p.dirname(workspaceFile.path);
        final relativePath = p.relative(
          project.localVersionSymlinkPath,
          from: workspaceDir,
        );
        sdkPath = convertToPosixPath(relativePath);
      } else {
        sdkPath = project.localVersionSymlinkPath;
      }

      // Update Flutter SDK setting
      workspaceSettings['settings']['dart.flutterSdkPath'] = sdkPath;

      // Write changes back
      workspaceFile.writeAsStringSync(prettyJson(workspaceSettings));

      final relativePath = p.relative(
        workspaceFile.path,
        from: context.workingDirectory,
      );
      logger.success(
        'Updated Flutter SDK path in workspace file: $relativePath',
      );
    } catch (e) {
      final relativePath = p.relative(
        workspaceFile.path,
        from: context.workingDirectory,
      );
      logger.err('Failed to update workspace file $relativePath: $e');
      // Continue to next workspace file
    }
  }

  /// Updates VS Code configuration for the project.
  ///
  /// Configures the "dart.flutterSdkPath" setting to point to the FVM-managed
  /// Flutter SDK in both folder settings and workspace settings if applicable.
  ///
  /// If [updateVscodeSettings] is disabled in the project config, this operation is skipped.
  ///
  /// Returns void, but logs success or error messages.
  FutureOr<void> call(Project project) {
    // Check if VS Code settings management is enabled for this project
    final updateVscodeSettings = project.config?.updateVscodeSettings ?? true;

    if (project.pinnedVersion == null) {
      logger.warn(
        '$kPackageName: Project is not using a pinned Flutter version, skipping $kVsCode settings update.',
      );
    }

    if (!updateVscodeSettings) {
      logger.detail(
        '$kPackageName does not manage $kVsCode settings for this project.',
      );

      // Check if project is using VS Code in some way
      final isUsingVscode = isVsCode() ||
          _hasVsCodeFiles(project) ||
          _findWorkspaceFile(project) != null;

      if (isUsingVscode) {
        logger.warn(
          'You are using $kVsCode, but $kPackageName is '
          'not managing $kVsCode settings for this project. '
          'Please remove "updateVscodeSettings: false" from $kFvmConfigFileName',
        );
      }

      return null;
    }

    // Update project folder settings
    _updateFolderSettings(project);

    // Find and update workspace files if they exist
    _updateWorkspaceFiles(project);

    return null;
  }
}
