import 'package:fvm/fvm.dart';
import 'package:fvm/src/workflows/resolve_project_deps.workflow.dart';
import 'package:fvm/src/workflows/setup_flutter.workflow.dart';
import 'package:fvm/src/workflows/setup_gitignore.workflow.dart';
import 'package:fvm/src/workflows/update_melos_settings.workflow.dart';
import 'package:fvm/src/workflows/update_project_references.workflow.dart';
import 'package:fvm/src/workflows/update_vscode_settings.workflow.dart';
import 'package:fvm/src/workflows/use_version.workflow.dart';
import 'package:fvm/src/workflows/verify_project.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('UseVersionWorkflow', () {
    test('runs phases in order and passes updated project downstream',
        () async {
      final harness = _UseHarness(gitIgnoreResult: false);

      await harness.run();

      expect(harness.events, [
        'setup',
        'verify',
        'references',
        'gitignore:original',
        'dependencies:stable',
        'vscode:stable',
        'melos:stable',
      ]);
    });

    test('honors setup and dependency skip flags', () async {
      final harness = _UseHarness();

      await harness.run(skipSetup: true, skipPubGet: true);

      expect(harness.events, [
        'verify',
        'references',
        'gitignore:original',
        'vscode:stable',
        'melos:stable',
      ]);
    });

    test('passes refreshed post-setup SDK metadata downstream', () async {
      final harness = _UseHarness();

      await harness.run();

      final dependencyVersion = harness.dependencyVersions.single;
      expect(dependencyVersion, isNot(same(harness.version)));
      expect(dependencyVersion.isSetup, isTrue);
      expect(dependencyVersion.dartSdkVersion, '3.10.0');
    });

    test('stops after a critical project-reference failure', () async {
      final harness = _UseHarness(failReferences: true);

      await expectLater(harness.run(), throwsStateError);

      expect(harness.events, ['setup', 'verify', 'references']);
    });
  });
}

final class _UseHarness {
  final events = <String>[];
  final dependencyVersions = <CacheFlutterVersion>[];
  late final FvmContext context;
  late final Project project;
  late final Project updatedProject;
  late final CacheFlutterVersion version;

  _UseHarness({bool failReferences = false, bool gitIgnoreResult = true}) {
    context = TestFactory.context(
      generators: {
        CacheService: _RefreshingCacheService.new,
        SetupFlutterWorkflow: (context) => _Setup(context, events),
        VerifyProjectWorkflow: (context) => _Verify(context, events),
        UpdateProjectReferencesWorkflow: (context) => _References(
              context,
              events,
              () => updatedProject,
              fail: failReferences,
            ),
        SetupGitIgnoreWorkflow: (context) => _GitIgnore(
              context,
              events,
              result: gitIgnoreResult,
            ),
        ResolveProjectDependenciesWorkflow: (context) => _Dependencies(
              context,
              events,
              dependencyVersions,
            ),
        UpdateVsCodeSettingsWorkflow: (context) => _VsCode(context, events),
        UpdateMelosSettingsWorkflow: (context) => _Melos(context, events),
      },
    );
    project =
        Project(config: null, path: context.workingDirectory, pubspec: null);
    updatedProject = Project(
      config: const ProjectConfig(flutter: 'stable'),
      path: project.path,
      pubspec: null,
    );
    version = CacheFlutterVersion.fromVersion(
      FlutterVersion.parse('stable'),
      directory: p.join(context.versionsCachePath, 'stable'),
    );
  }

  Future<void> run({bool skipSetup = false, bool skipPubGet = false}) {
    return context.get<UseVersionWorkflow>()(
      version: version,
      project: project,
      skipSetup: skipSetup,
      skipPubGet: skipPubGet,
    );
  }
}

final class _Setup extends SetupFlutterWorkflow {
  final List<String> events;
  _Setup(super.context, this.events);

  @override
  Future<void> call(CacheFlutterVersion version) async {
    events.add('setup');
    (context.get<CacheService>() as _RefreshingCacheService).setupComplete =
        true;
  }
}

final class _RefreshingCacheService extends CacheService {
  _RefreshingCacheService(super.context);

  bool setupComplete = false;

  @override
  CacheFlutterVersion? getVersion(FlutterVersion version) {
    if (!setupComplete) return null;

    return CacheFlutterVersion(
      version.name,
      releaseChannel: version.releaseChannel,
      type: version.type,
      fork: version.fork,
      directory: p.join(context.versionsCachePath, version.name),
      flutterSdkVersion: '3.10.0',
      dartSdkVersion: '3.10.0',
      isSetup: true,
    );
  }
}

final class _Verify extends VerifyProjectWorkflow {
  final List<String> events;
  _Verify(super.context, this.events);

  @override
  void call(Project project, {required bool force}) => events.add('verify');
}

final class _References extends UpdateProjectReferencesWorkflow {
  final List<String> events;
  final Project Function() updatedProject;
  final bool fail;
  _References(super.context, this.events, this.updatedProject,
      {this.fail = false});

  @override
  Future<Project> call(
    Project project,
    CacheFlutterVersion version, {
    String? flavor,
    bool force = false,
  }) async {
    events.add('references');
    if (fail) throw StateError('reference update failed');
    return updatedProject();
  }
}

final class _GitIgnore extends SetupGitIgnoreWorkflow {
  final List<String> events;
  final bool result;
  _GitIgnore(super.context, this.events, {required this.result});

  @override
  bool call(Project project) {
    events.add('gitignore:${project.config?.flutter ?? 'original'}');
    return result;
  }
}

final class _Dependencies extends ResolveProjectDependenciesWorkflow {
  final List<String> events;
  final List<CacheFlutterVersion> versions;
  _Dependencies(super.context, this.events, this.versions);

  @override
  Future<bool> call(
    Project project,
    CacheFlutterVersion version, {
    required bool force,
  }) async {
    events.add('dependencies:${project.config?.flutter}');
    versions.add(version);
    return true;
  }
}

final class _VsCode extends UpdateVsCodeSettingsWorkflow {
  final List<String> events;
  _VsCode(super.context, this.events);

  @override
  Future<void> call(Project project) async {
    events.add('vscode:${project.config?.flutter}');
  }
}

final class _Melos extends UpdateMelosSettingsWorkflow {
  final List<String> events;
  _Melos(super.context, this.events);

  @override
  Future<void> call(Project project) async {
    events.add('melos:${project.config?.flutter}');
  }
}
