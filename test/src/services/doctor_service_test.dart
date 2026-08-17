import 'dart:convert';
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/doctor_service.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  late TempDirectoryTracker tempDirs;

  setUp(() => tempDirs = TempDirectoryTracker());
  tearDown(() => tempDirs.cleanUp());

  test('reports healthy project, IDE, PATH, and runtime data', () {
    final fixture = _createDoctorFixture(tempDirs.create());

    final report = DoctorService(fixture.context).inspect();

    expect(report.sections.map((section) => section.name), [
      'Project',
      'IDEs',
      'Environment',
      'Runtime',
    ]);
    expect(_check(report, 'Project', 'Pinned Version').value, 'stable');
    expect(
      _check(report, 'IDEs', 'VS Code pinned version').status,
      DoctorStatus.ok,
    );
    expect(
      _check(report, 'IDEs', 'IntelliJ pinned version').status,
      DoctorStatus.ok,
    );
    expect(
      _check(report, 'Environment', 'Flutter PATH').value,
      path.join(fixture.binDir.path, flutterExecFileName),
    );
    expect(
      _check(report, 'Environment', 'Dart PATH').value,
      path.join(fixture.binDir.path, dartExecFileName),
    );
    expect(_check(report, 'Runtime', 'Dart runtime').value, isNotEmpty);
    expect(report.recommendations, isEmpty);
  });

  test('reports missing and malformed VS Code settings without throwing', () {
    final missing = _createDoctorFixture(
      tempDirs.create(),
      vscodeSettings: null,
    );
    final malformed = _createDoctorFixture(
      tempDirs.create(),
      vscodeSettings: '{not-json',
    );

    final missingCheck = _check(
      DoctorService(missing.context).inspect(),
      'IDEs',
      'VS Code',
    );
    final malformedReport = DoctorService(malformed.context).inspect();
    final malformedCheck = _check(malformedReport, 'IDEs', 'VS Code settings');

    expect(missingCheck.value, 'Found .vscode, but no settings.json');
    expect(missingCheck.status, DoctorStatus.warning);
    expect(
      malformedCheck.value,
      contains('Could not get vscode settings, please check settings.json'),
    );
    expect(malformedCheck.status, DoctorStatus.error);
    expect(
      malformedReport.recommendations,
      contains(path.join(malformed.root.path, '.vscode', 'settings.json')),
    );
  });

  test('reports a mismatched VS Code SDK path', () {
    final fixture = _createDoctorFixture(
      tempDirs.create(),
      vscodeSettings: jsonEncode({'dart.flutterSdkPath': '/wrong/flutter'}),
    );

    final check = _check(
      DoctorService(fixture.context).inspect(),
      'IDEs',
      'VS Code pinned version',
    );

    expect(check.value, 'false');
    expect(check.status, DoctorStatus.warning);
  });

  test('reports missing and malformed IntelliJ flutter.sdk entries', () {
    final missing = _createDoctorFixture(
      tempDirs.create(),
      localProperties: 'android.sdk=/tmp/android\n',
    );
    final malformed = _createDoctorFixture(
      tempDirs.create(),
      localProperties: 'flutter.sdk=\n',
    );

    expect(
      _check(
        DoctorService(missing.context).inspect(),
        'IDEs',
        'IntelliJ flutter.sdk',
      ).value,
      'flutter.sdk not found in local.properties',
    );
    final malformedCheck = _check(
      DoctorService(malformed.context).inspect(),
      'IDEs',
      'IntelliJ flutter.sdk',
    );
    expect(malformedCheck.value, 'Malformed entry in local.properties');
    expect(malformedCheck.status, DoctorStatus.error);
  });

  test('reports a missing pinned-version symlink with a repair command', () {
    final fixture = _createDoctorFixture(
      tempDirs.create(),
      createVersionLink: false,
    );

    final report = DoctorService(fixture.context).inspect();
    final check = _check(report, 'IDEs', 'IntelliJ pinned version');

    expect(check.value, 'Version symlink missing - run "fvm use stable"');
    expect(check.status, DoctorStatus.error);
    expect(report.recommendations, contains('fvm use stable'));
  });
}

DoctorReportCheck _check(
  DoctorReport report,
  String sectionName,
  String label,
) => report.sections
    .singleWhere((section) => section.name == sectionName)
    .checks
    .singleWhere((check) => check.label == label);

({FvmContext context, Directory root, Directory binDir}) _createDoctorFixture(
  Directory root, {
  String? vscodeSettings = _defaultSettings,
  String? localProperties,
  bool createVersionLink = true,
}) {
  File(path.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: doctor_fixture
dependencies:
  flutter:
    sdk: flutter
''');
  createProjectConfig(const ProjectConfig(flutter: 'stable'), root);
  File(path.join(root.path, '.gitignore')).writeAsStringSync('.fvm/\n');
  final dartTool = Directory(path.join(root.path, '.dart_tool'))..createSync();
  File(path.join(dartTool.path, 'package_config.json')).writeAsStringSync(
    jsonEncode({'configVersion': 2, 'generatorVersion': '3.10.0'}),
  );

  final sdk = Directory(path.join(root.path, 'sdk'))..createSync();
  final versionLink = Link(path.join(root.path, '.fvm', 'versions', 'stable'));
  if (createVersionLink) {
    versionLink.parent.createSync(recursive: true);
    versionLink.createSync(sdk.path);
  }

  final vscode = Directory(path.join(root.path, '.vscode'))..createSync();
  if (vscodeSettings != null) {
    final contents = vscodeSettings == _defaultSettings
        ? jsonEncode({'dart.flutterSdkPath': versionLink.path})
        : vscodeSettings;
    File(path.join(vscode.path, 'settings.json')).writeAsStringSync(contents);
  }

  final android = Directory(path.join(root.path, 'android'))..createSync();
  File(
    path.join(android.path, 'local.properties'),
  ).writeAsStringSync(localProperties ?? 'flutter.sdk=${sdk.path}\n');
  final libraries = Directory(path.join(root.path, '.idea', 'libraries'))
    ..createSync(recursive: true);
  File(
    path.join(libraries.path, 'Dart_SDK.xml'),
  ).writeAsStringSync(r'<root url="file://$PROJECT_DIR$/.fvm/flutter_sdk" />');

  final binDir = Directory(path.join(root.path, 'bin'))..createSync();
  for (final executable in [flutterExecFileName, dartExecFileName]) {
    final file = File(path.join(binDir.path, executable))
      ..writeAsStringSync('#!/bin/sh\n');
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['+x', file.path]);
    }
  }

  final context = FvmContext.create(
    isTest: true,
    workingDirectoryOverride: root.path,
    environmentOverrides: {...Platform.environment, 'PATH': binDir.path},
    configOverrides: const AppConfig(privilegedAccess: false),
  );

  return (context: context, root: root, binDir: binDir);
}

const _defaultSettings = '__default__';
