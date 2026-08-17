// ignore_for_file: member-ordering

import 'dart:io';

import 'package:jsonc/jsonc.dart' as jsonc;
import 'package:path/path.dart' as path;

import '../models/config_model.dart';
import '../models/project_model.dart';
import '../utils/convert_posix_path.dart';
import '../utils/which.dart';
import 'base_service.dart';
import 'project_service.dart';

final class DoctorReport {
  final List<DoctorReportSection> sections;
  final List<String> recommendations;

  const DoctorReport({required this.sections, required this.recommendations});
}

final class DoctorReportSection {
  final String name;
  final List<DoctorReportCheck> checks;

  const DoctorReportSection({required this.name, required this.checks});
}

enum DoctorStatus { ok, info, warning, error }

final class DoctorReportCheck {
  final String label;
  final String value;
  final DoctorStatus status;

  const DoctorReportCheck({
    required this.label,
    required this.value,
    required this.status,
  });
}

class DoctorService extends ContextualService {
  const DoctorService(super.context);

  String _dartToolGeneratorVersion(Project project) {
    try {
      return project.dartToolGeneratorVersion ?? 'Not available';
    } on FormatException {
      return 'Invalid .dart_tool/package_config.json';
    } on TypeError {
      return 'Invalid .dart_tool/package_config.json';
    }
  }

  DoctorReport inspect() {
    final project = get<ProjectService>().findAncestor();
    final sections = [
      projectSection(project),
      ideSection(project),
      environmentSection(),
      runtimeSection(),
    ];

    return DoctorReport(
      sections: sections,
      recommendations: _recommendations(project, sections),
    );
  }

  DoctorReportSection projectSection(Project project) {
    final generatorVersion = _dartToolGeneratorVersion(project);

    return DoctorReportSection(
      name: 'Project',
      checks: [
        DoctorReportCheck(
          label: 'Directory',
          value: project.path,
          status: DoctorStatus.ok,
        ),
        DoctorReportCheck(
          label: 'Active Flavor',
          value: project.activeFlavor ?? 'None',
          status: DoctorStatus.info,
        ),
        DoctorReportCheck(
          label: 'Is Flutter Project',
          value: project.isFlutter ? 'Yes' : 'No',
          status: project.isFlutter ? DoctorStatus.ok : DoctorStatus.warning,
        ),
        DoctorReportCheck(
          label: 'Dart Tool Generator Version',
          value: generatorVersion,
          status: generatorVersion.startsWith('Invalid ')
              ? DoctorStatus.error
              : DoctorStatus.info,
        ),
        DoctorReportCheck(
          label: 'Dart tool version',
          value: project.dartToolVersion ?? 'Not available',
          status: DoctorStatus.info,
        ),
        DoctorReportCheck(
          label: '.gitignore Present',
          value: project.gitIgnoreFile.existsSync() ? 'Yes' : 'No',
          status: project.gitIgnoreFile.existsSync()
              ? DoctorStatus.ok
              : DoctorStatus.warning,
        ),
        DoctorReportCheck(
          label: 'Config Present',
          value: project.hasConfig ? 'Yes' : 'No',
          status: project.hasConfig ? DoctorStatus.ok : DoctorStatus.warning,
        ),
        DoctorReportCheck(
          label: 'Pinned Version',
          value: project.pinnedVersion?.nameWithAlias ?? 'None',
          status: project.pinnedVersion == null
              ? DoctorStatus.warning
              : DoctorStatus.ok,
        ),
        DoctorReportCheck(
          label: 'Config path',
          value: path.relative(project.configPath, from: project.path),
          status: DoctorStatus.info,
        ),
        DoctorReportCheck(
          label: 'Local cache dir',
          value: path.relative(
            project.localVersionsCachePath,
            from: project.path,
          ),
          status: DoctorStatus.info,
        ),
        DoctorReportCheck(
          label: 'Version symlink',
          value: path.relative(
            project.localVersionSymlinkPath,
            from: project.path,
          ),
          status: Link(project.localVersionSymlinkPath).existsSync()
              ? DoctorStatus.ok
              : DoctorStatus.warning,
        ),
      ],
    );
  }

  DoctorReportSection ideSection(Project project) => DoctorReportSection(
    name: 'IDEs',
    checks: [..._vscodeChecks(project), ..._intellijChecks(project)],
  );

  List<DoctorReportCheck> _vscodeChecks(Project project) {
    final vscodeDir = Directory(path.join(project.path, '.vscode'));
    final settingsFile = File(path.join(vscodeDir.path, 'settings.json'));
    if (!vscodeDir.existsSync()) {
      return const [
        DoctorReportCheck(
          label: 'VS Code',
          value: 'No .vscode directory found',
          status: DoctorStatus.info,
        ),
      ];
    }
    if (!settingsFile.existsSync()) {
      return const [
        DoctorReportCheck(
          label: 'VS Code',
          value: 'Found .vscode, but no settings.json',
          status: DoctorStatus.warning,
        ),
      ];
    }

    try {
      final decoded = jsonc.jsonc.decode(settingsFile.readAsStringSync());
      if (decoded is! Map) throw const FormatException('Expected an object');
      final sdkPath = decoded['dart.flutterSdkPath'];
      final expectedSdkPath = resolveVsCodeSdkPath(
        project.localVersionSymlinkPath,
        privilegedAccess: context.privilegedAccess,
        relativeTo: project.path,
      );
      final matchesPinnedVersion =
          sdkPath is String && convertToPosixPath(sdkPath) == expectedSdkPath;

      return [
        DoctorReportCheck(
          label: 'VS Code SDK path',
          value: sdkPath?.toString() ?? 'None',
          status: sdkPath is String ? DoctorStatus.info : DoctorStatus.warning,
        ),
        DoctorReportCheck(
          label: 'VS Code pinned version',
          value: matchesPinnedVersion.toString(),
          status: matchesPinnedVersion ? DoctorStatus.ok : DoctorStatus.warning,
        ),
      ];
    } on FormatException {
      return [
        DoctorReportCheck(
          label: 'VS Code settings',
          value:
              'Could not get vscode settings, please check settings.json at ${settingsFile.path}',
          status: DoctorStatus.error,
        ),
      ];
    } on TypeError {
      return [
        DoctorReportCheck(
          label: 'VS Code settings',
          value:
              'Could not get vscode settings, please check settings.json at ${settingsFile.path}',
          status: DoctorStatus.error,
        ),
      ];
    }
  }

  List<DoctorReportCheck> _intellijChecks(Project project) {
    final checks = <DoctorReportCheck>[];
    final localPropertiesFile = File(
      path.join(project.path, 'android', 'local.properties'),
    );
    String? sdkPath;
    if (!localPropertiesFile.existsSync()) {
      checks.add(
        const DoctorReportCheck(
          label: 'IntelliJ flutter.sdk',
          value: 'No local.properties file found in android directory',
          status: DoctorStatus.info,
        ),
      );
    } else {
      final sdkLines = localPropertiesFile.readAsLinesSync().where(
        (line) => line.startsWith('flutter.sdk'),
      );
      if (sdkLines.isEmpty) {
        checks.add(
          const DoctorReportCheck(
            label: 'IntelliJ flutter.sdk',
            value: 'flutter.sdk not found in local.properties',
            status: DoctorStatus.warning,
          ),
        );
      } else {
        final parts = sdkLines.first.split('=');
        final sdkValue = parts.length < 2
            ? ''
            : parts.sublist(1).join('=').trim();
        if (sdkValue.isEmpty) {
          checks.add(
            const DoctorReportCheck(
              label: 'IntelliJ flutter.sdk',
              value: 'Malformed entry in local.properties',
              status: DoctorStatus.error,
            ),
          );
        } else {
          sdkPath = sdkValue;
          checks.add(
            DoctorReportCheck(
              label: 'IntelliJ flutter.sdk',
              value: sdkPath,
              status: DoctorStatus.info,
            ),
          );
        }
        checks.add(_intellijPinnedVersionCheck(project, sdkPath));
      }
    }

    checks.add(_intellijSdkPathCheck(project));

    return checks;
  }

  DoctorReportCheck _intellijPinnedVersionCheck(
    Project project,
    String? sdkPath,
  ) {
    final pinnedVersion = project.pinnedVersion;
    if (pinnedVersion == null) {
      return const DoctorReportCheck(
        label: 'IntelliJ pinned version',
        value: 'No version pinned - run "fvm use <version>"',
        status: DoctorStatus.warning,
      );
    }

    final cacheVersionLink = Link(project.localVersionSymlinkPath);
    if (!cacheVersionLink.existsSync()) {
      return DoctorReportCheck(
        label: 'IntelliJ pinned version',
        value:
            'Version symlink missing - run "fvm use ${pinnedVersion.nameWithAlias}"',
        status: DoctorStatus.error,
      );
    }

    try {
      final resolvedLink = cacheVersionLink.resolveSymbolicLinksSync();
      if (sdkPath == null) {
        return const DoctorReportCheck(
          label: 'IntelliJ pinned version',
          value: 'Cannot validate - malformed flutter.sdk entry',
          status: DoctorStatus.error,
        );
      }
      final matches = sdkPath == resolvedLink;

      return DoctorReportCheck(
        label: 'IntelliJ pinned version',
        value: matches.toString(),
        status: matches ? DoctorStatus.ok : DoctorStatus.warning,
      );
    } on FileSystemException {
      return DoctorReportCheck(
        label: 'IntelliJ pinned version',
        value:
            'Cannot resolve symlink - run "fvm use ${pinnedVersion.nameWithAlias}"',
        status: DoctorStatus.error,
      );
    }
  }

  DoctorReportCheck _intellijSdkPathCheck(Project project) {
    final dartSdkFile = File(
      path.join(project.path, '.idea', 'libraries', 'Dart_SDK.xml'),
    );
    if (!dartSdkFile.existsSync()) {
      return const DoctorReportCheck(
        label: 'IntelliJ SDK Path',
        value: 'No .idea folder found',
        status: DoctorStatus.info,
      );
    }

    final contents = dartSdkFile.readAsStringSync();
    final pointsToProject =
        !contents.contains(r'$USER_HOME$') &&
        contents.contains(r'$PROJECT_DIR$');
    final usesSymlink = contents.contains('.fvm/flutter_sdk');
    if (pointsToProject && usesSymlink) {
      return const DoctorReportCheck(
        label: 'IntelliJ SDK Path',
        value:
            'SDK Path points to project directory. IntelliJ will dynamically switch SDK when using "fvm use"',
        status: DoctorStatus.ok,
      );
    }
    if (pointsToProject) {
      return const DoctorReportCheck(
        label: 'IntelliJ SDK Path',
        value:
            'SDK Path points to project directory, but does not use the flutter_sdk symlink. Using "fvm use" will break the project. Please consult documentation.',
        status: DoctorStatus.warning,
      );
    }

    return const DoctorReportCheck(
      label: 'IntelliJ SDK Path',
      value:
          'SDK Path does not point to the project directory. "fvm use" will not make IntelliJ switch Flutter version. Please consult documentation.',
      status: DoctorStatus.warning,
    );
  }

  DoctorReportSection environmentSection() {
    final searchPath = context.environment['PATH'];
    final pathExtensions = context.environment['PATHEXT'];
    final flutterPath = which(
      'flutter',
      searchPath: searchPath,
      pathExtensions: pathExtensions,
    );
    final dartPath = which(
      'dart',
      searchPath: searchPath,
      pathExtensions: pathExtensions,
    );

    return DoctorReportSection(
      name: 'Environment',
      checks: [
        DoctorReportCheck(
          label: 'Flutter PATH',
          value: flutterPath ?? 'Not found',
          status: flutterPath == null ? DoctorStatus.warning : DoctorStatus.ok,
        ),
        DoctorReportCheck(
          label: 'Dart PATH',
          value: dartPath ?? 'Not found',
          status: dartPath == null ? DoctorStatus.warning : DoctorStatus.ok,
        ),
        for (final option in ConfigOptions.values)
          DoctorReportCheck(
            label: option.envKey,
            value: context.environment[option.envKey] ?? 'N/A',
            status: DoctorStatus.info,
          ),
      ],
    );
  }

  DoctorReportSection runtimeSection() => DoctorReportSection(
    name: 'Runtime',
    checks: [
      DoctorReportCheck(
        label: 'OS',
        value: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        status: DoctorStatus.info,
      ),
      DoctorReportCheck(
        label: 'Dart Locale',
        value: Platform.localeName,
        status: DoctorStatus.info,
      ),
      DoctorReportCheck(
        label: 'Dart runtime',
        value: Platform.version,
        status: DoctorStatus.info,
      ),
    ],
  );

  List<String> _recommendations(
    Project project,
    List<DoctorReportSection> sections,
  ) {
    final recommendations = <String>{};
    final problemLabels = sections
        .expand((section) => section.checks)
        .where(
          (check) =>
              check.status == DoctorStatus.warning ||
              check.status == DoctorStatus.error,
        )
        .map((check) => check.label)
        .toSet();

    if (problemLabels.any((label) => label.startsWith('VS Code'))) {
      recommendations.add(path.join(project.path, '.vscode', 'settings.json'));
    }
    if (problemLabels.contains('IntelliJ flutter.sdk')) {
      recommendations.add(
        path.join(project.path, 'android', 'local.properties'),
      );
    }
    if (problemLabels.contains('IntelliJ SDK Path')) {
      recommendations.add(
        path.join(project.path, '.idea', 'libraries', 'Dart_SDK.xml'),
      );
    }
    if (problemLabels.contains('IntelliJ pinned version') ||
        problemLabels.contains('Pinned Version') ||
        problemLabels.contains('Version symlink')) {
      recommendations.add(
        'fvm use ${project.pinnedVersion?.nameWithAlias ?? '<version>'}',
      );
    }
    if (problemLabels.contains('Flutter PATH') ||
        problemLabels.contains('Dart PATH')) {
      recommendations.add(context.versionsCachePath);
    }

    return recommendations.toList();
  }
}
