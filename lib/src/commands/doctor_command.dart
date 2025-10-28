import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:io/io.dart';
import 'package:jsonc/jsonc.dart';
import 'package:path/path.dart' as p;

import '../models/config_model.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../utils/console_utils.dart';
import '../utils/constants.dart';
import '../utils/exceptions.dart';
import '../utils/which.dart';
import 'base_command.dart';

/// Information about fvm environment
class DoctorCommand extends BaseFvmCommand {
  @override
  final name = 'doctor';

  @override
  final description =
      'Shows detailed information about the FVM environment and project configuration';

  final console = Console();

  DoctorCommand(super.context);

  void _printProject(Project project) {
    logger.info('Project:');
    final table = createTable(['Project', project.name]);

    table.insertRows([
      ['Directory', project.path],
      ['Active Flavor', project.activeFlavor ?? 'None'],
      ['Is Flutter Project', project.isFlutter ? 'Yes' : 'No'],
      [
        'Dart Tool Generator Version',
        project.dartToolGeneratorVersion ?? 'Not available',
      ],
      ['Dart tool version', project.dartToolVersion ?? 'Not available'],
      ['.gitignore Present', project.gitIgnoreFile.existsSync() ? 'Yes' : 'No'],
      ['Config Present', project.hasConfig ? 'Yes' : 'No'],
      ['Pinned Version', project.pinnedVersion ?? 'None'],
      ['Config path', p.relative(project.configPath, from: project.path)],
      [
        'Local cache dir',
        p.relative(project.localVersionsCachePath, from: project.path),
      ],
      [
        'Version symlink',
        p.relative(project.localVersionSymlinkPath, from: project.path),
      ],
    ]);

    logger.write(table.toString());
    logger.info();
  }

  void _printIdeLinks(Project project) {
    logger
      ..info()
      ..info('IDEs:');
    final table = createTable(['IDEs', 'Value']);

    table.insertRow([kVsCode]);
    // Check for .vscode directory
    final vscodeDir = Directory(p.join(project.path, '.vscode'));
    final settingsPath = p.join(vscodeDir.path, 'settings.json');
    final settingsFile = File(settingsPath);

    if (vscodeDir.existsSync()) {
      if (settingsFile.existsSync()) {
        try {
          final settings = jsonc.decode(settingsFile.readAsStringSync());

          final relativeSymlinkPath = p.relative(
            project.localVersionSymlinkPath,
            from: project.path,
          );

          final sdkPath = settings['dart.flutterSdkPath'];

          table.insertRow(['dart.flutterSdkPath', sdkPath ?? 'None']);
          table.insertRow([
            'Matches pinned version:',
            sdkPath == relativeSymlinkPath,
          ]);
        } on FormatException catch (_, stackTrace) {
          logger
            ..err('Error parsing Vscode settings.json on ${settingsFile.path}')
            ..err(
              'Please use a tool like https://jsonformatter.curiousconcept.com to validate and fix it',
            );
          Error.throwWithStackTrace(
            AppException(
              'Could not get vscode settings, please check settings.json',
            ),
            stackTrace,
          );
        }
      } else {
        table.insertRow([kVsCode, 'Found .vscode, but no settings.json']);
      }
    } else {
      table.insertRow([kVsCode, 'No .vscode directory found']);
    }

    table.insertRow([kIntelliJ]);

    // Get local properties file within flutter project
    final localPropertiesFile = File(
      p.join(project.path, 'android', 'local.properties'),
    );

    if (localPropertiesFile.existsSync()) {
      final localProperties = localPropertiesFile.readAsLinesSync();
      final sdkPath = localProperties
          .firstWhere((line) => line.startsWith('flutter.sdk'))
          .split('=')[1];
      final cacheVersionLink = Link(project.localVersionSymlinkPath);
      final resolvedLink = cacheVersionLink.resolveSymbolicLinksSync();

      table.insertRow(['flutter.sdk', sdkPath]);
      table.insertRow(['Matches pinned version:', sdkPath == resolvedLink]);
    } else {
      table.insertRow([
        kIntelliJ,
        'No local.properties file found in android directory',
      ]);
    }

    final dartSdkFile = File(
      p.join(project.path, '.idea', 'libraries', 'Dart_SDK.xml'),
    );

    if (dartSdkFile.existsSync()) {
      final dartSdk = dartSdkFile.readAsStringSync();
      final containsUserHome = dartSdk.contains(r'$USER_HOME$');
      final containsProjectDir = dartSdk.contains(r'$PROJECT_DIR$');
      final containsSymLinkName = dartSdk.contains('.fvm/flutter_sdk');

      if (!containsUserHome && containsProjectDir) {
        if (containsSymLinkName) {
          table.insertRow([
            'SDK Path',
            'SDK Path points to project directory. $kIntelliJ will dynamically switch SDK when using "fvm use"',
          ]);
        } else {
          table.insertRow([
            'SDK Path',
            'SDK Path points to project directory, but does not use the flutter_sdk symlink. Using "fvm use" will break the project. Please consult documentation.',
          ]);
        }
      } else {
        table.insertRow([
          'SDK Path',
          'SDK Path does not point to the project directory. "fvm use" will not make $kIntelliJ switch Flutter version. Please consult documentation.',
        ]);
      }
    } else {
      table.insertRow([kIntelliJ, 'No .idea folder found']);
    }

    logger.write(table.toString());
  }

  void _printEnvironmentDetails(String? flutterWhich, String? dartWhich) {
    logger
      ..info()
      ..info('Environment:');

    var table = createTable(['Environment Variables', 'Value']);

    table.insertRows([
      ['Flutter PATH', flutterWhich ?? 'Not found'],
      ['Dart PATH', dartWhich ?? 'Not found'],
    ]);

    for (var key in ConfigOptions.values) {
      table.insertRow([key.envKey, context.environment[key.envKey] ?? 'N/A']);
    }

    table.insertRows([
      ['Flutter PATH', flutterWhich ?? 'Not found'],
      ['Dart PATH', dartWhich ?? 'Not found'],
    ]);

    logger.write(table.toString());

    table = createTable(['Platform', 'Value']);

    table.insertRows([
      ['OS', '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'],
      ['Dart Locale', Platform.localeName],
      ['Dart runtime', Platform.version],
    ]);

    logger.write(table.toString());
  }

  @override
  Future<int> run() async {
    final project = get<ProjectService>().findAncestor();
    final flutterWhich = which('flutter');
    final dartWhich = which('dart');

    console.writeLine('FVM Doctor:');
    console.writeLine('-' * console.windowWidth);

    _printProject(project);
    _printIdeLinks(project);
    _printEnvironmentDetails(flutterWhich, dartWhich);

    return ExitCode.success.code;
  }
}
