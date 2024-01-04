import 'dart:convert';
import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/which.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';

import '../services/logger_service.dart';
import 'base_command.dart';

/// Information about fvm environment
class DoctorCommand extends BaseCommand {
  @override
  final name = 'doctor';

  @override
  final description = 'Shows information about environment, '
      'and project configuration.';

  final console = Console();

  /// Constructor
  DoctorCommand();

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
      ['.gitignore Present', project.gitignoreFile.existsSync() ? 'Yes' : 'No'],
      ['Config Present', project.hasConfig ? 'Yes' : 'No'],
      ['Pinned Version', project.pinnedVersion ?? 'None'],
      ['Config path', relative(project.configPath, from: project.path)],
      [
        'Local cache dir',
        relative(project.localVersionsCachePath, from: project.path),
      ],
      [
        'Version symlink',
        relative(project.localVersionSymlinkPath, from: project.path),
      ],
    ]);

    logger.write(table.toString());
    logger.spacer;
  }

  void _printIdeLinks(Project project) {
    logger
      ..spacer
      ..info('IDEs:');
    final table = createTable(['IDEs', 'Value']);

    table.insertRow([kVsCode]);
    // Check for .vscode directory
    final vscodeDir = Directory(join(project.path, '.vscode'));
    final settingsPath = join(vscodeDir.path, 'settings.json');
    final settingsFile = File(settingsPath);

    if (vscodeDir.existsSync()) {
      if (settingsFile.existsSync()) {
        try {
          final settings = jsonDecode(settingsFile.readAsStringSync());

          final relativeSymlinkPath = relative(
            project.localVersionSymlinkPath,
            from: project.path,
          );

          final sdkPath = settings['dart.flutterSdkPath'];

          table.insertRow(['dart.flutterSdkPath', sdkPath ?? 'None']);
          table.insertRow(
            ['Matches pinned version:', sdkPath == relativeSymlinkPath],
          );
        } on FormatException {
          logger
            ..err('Error parsing Vscode settings.json on ${settingsFile.path}')
            ..err(
              'Please use a tool like https://jsonformatter.curiousconcept.com to validate and fix it',
            );
          throw AppException(
            'Could not get vscode settings, please check settings.json',
          );
        }
      } else {
        table.insertRow([kVsCode, 'Found .vscode, but no settings.json']);
      }
    } else {
      table.insertRow([kVsCode, 'No .vscode directory found']);
    }

    table.insertRow([kIntelliJ]);

    // Get localproperties file within flutter project
    final localPropertiesFile =
        File(join(project.path, 'android', 'local.properties'));

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

    final dartSdkFile =
        File(join(project.path, '.idea', 'libraries', 'Dart_SDK.xml'));

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
      table.insertRow([
        kIntelliJ,
        'No .idea folder found',
      ]);
    }

    logger.write(table.toString());
  }

  void _printEnvironmentDetails(String? flutterWhich, String? dartWhich) {
    logger
      ..spacer
      ..info('Environment:');

    var table = createTable(['Environment Variables', 'Value']);

    table.insertRows([
      ['Flutter PATH', flutterWhich ?? 'Not found'],
      ['Dart PATH', dartWhich ?? 'Not found'],
    ]);

    for (var key in ConfigKeys.values) {
      table.insertRow([key.envKey, ctx.environment[key.envKey] ?? 'N/A']);
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

  void printFVMDetails() {}
  @override
  Future<int> run() async {
    final project = ProjectService.fromContext.findAncestor();
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
