import 'dart:convert';
import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/console_utils.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/which.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';

import '../utils/logger.dart';
import 'base_command.dart';

/// Information about fvm environment
class DoctorCommand extends BaseCommand {
  @override
  final name = 'doctor';

  @override
  final description = 'Shows information about environment, '
      'and project configuration.';

  /// Constructor
  DoctorCommand();

  final console = Console();

  @override
  Future<int> run() async {
    final project = await ProjectService.instance.findAncestor();
    final flutterWhich = which('flutter');
    final dartWhich = which('dart');

    console.writeLine('FVM Doctor:');
    console.writeLine('-' * console.windowWidth);

    _printProject(project);
    _printIdeLinks(project);
    _printEnvironmentDetails(flutterWhich, dartWhich);

    return ExitCode.success.code;
  }

  void printFVMDetails(FVMContext context) {}
  void _printProject(Project project) {
    logger.info('Project:');
    final table = createTable()
      ..insertColumn(header: 'Project', alignment: TextAlignment.left)
      ..insertColumn(header: project.name, alignment: TextAlignment.left);

    table.insertRows([
      ['Directory', project.projectDir.path],
      ['Active Flavor', project.activeFlavor ?? 'None'],
      ['Is Flutter Project', project.isFlutter ? 'Yes' : 'No'],
      [
        'Dart Tool Generator Version',
        project.dartToolGeneratorVersion ?? 'Not available'
      ],
      ['Dart tool version', project.dartToolVersion ?? 'Not available'],
      ['.gitignore Present', project.gitignoreFile.existsSync() ? 'Yes' : 'No'],
      ['Config Present', project.hasConfig ? 'Yes' : 'No'],
      ['Pinned Version', project.pinnedVersion ?? 'None'],
      [
        'Config path',
        relative(project.configFile.path, from: project.projectDir.path)
      ],
      [
        'Local cache dir',
        relative(project.fvmCacheDir.path, from: project.projectDir.path)
      ],
      [
        'Version symlink',
        relative(
          project.cacheVersionSymlink.path,
          from: project.projectDir.path,
        )
      ],
    ]);

    logger.write(table.toString());
    logger.spacer;
  }

  void _printIdeLinks(Project project) {
    logger
      ..spacer
      ..info('IDEs:');
    final table = createTable()
      ..insertColumn(header: 'IDEs', alignment: TextAlignment.left)
      ..insertColumn(header: '', alignment: TextAlignment.left);
    table.insertRow(['VsCode']);
    // Check for .vscode directory
    final vscodeDir = Directory(join(project.projectDir.path, '.vscode'));
    final settingsPath = join(vscodeDir.path, 'settings.json');

    if (vscodeDir.existsSync()) {
      if (File(settingsPath).existsSync()) {
        final settings = jsonDecode(File(settingsPath).readAsStringSync());

        final relativeSymlinkPath = relative(
          project.cacheVersionSymlink.path,
          from: project.projectDir.path,
        );

        final sdkPath = settings['dart.flutterSdkPath'];

        table.insertRow(['dart.flutterSdkPath', sdkPath ?? 'None']);
        table.insertRow(
            ['Matches pinned version:', sdkPath == relativeSymlinkPath]);
      } else {
        table.insertRow(['VSCode', 'Found .vscode, but no settings.json']);
      }
    } else {
      table.insertRow(['VSCode', 'No .vscode directory found']);
    }

    table.insertRow(['Android Studio']);

    // Get localproperties file within flutter project
    final localPropertiesFile =
        File(join(project.projectDir.path, 'android', 'local.properties'));

    if (localPropertiesFile.existsSync()) {
      final localProperties = localPropertiesFile.readAsLinesSync();
      final sdkPath = localProperties
          .firstWhere((line) => line.startsWith('flutter.sdk'))
          .split('=')[1];

      final resolvedLink =
          project.cacheVersionSymlink.resolveSymbolicLinksSync();

      table.insertRow(['flutter.sdk', sdkPath]);
      table.insertRow(['Matches pinned version:', sdkPath == resolvedLink]);
    } else {
      table.insertRow([
        'Android Studio',
        'No local.properties file found in android directory'
      ]);
    }

    logger.write(table.toString());
  }

  void _printEnvironmentDetails(String? flutterWhich, String? dartWhich) {
    logger
      ..spacer
      ..info('Environment:');
    final table = createTable()
      ..insertColumn(
          header: 'Environment Detail', alignment: TextAlignment.left)
      ..insertColumn(header: 'Path/Value', alignment: TextAlignment.left);

    table.insertRows([
      ['Flutter Path', flutterWhich ?? 'Not found'],
      ['Dart Path', dartWhich ?? 'Not found'],
      ['FVM_HOME', ctx.environment['FVM_HOME'] ?? 'Not set'],
      ['OS', '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'],
      ['Dart Locale', Platform.localeName],
      ['Dart runtime', Platform.version],
    ]);

    logger.write(table.toString());
  }
}
