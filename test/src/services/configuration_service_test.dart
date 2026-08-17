import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/configuration_service.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  late TempDirectoryTracker tempDirs;

  setUp(() => tempDirs = TempDirectoryTracker());
  tearDown(() => tempDirs.cleanUp());

  test(
    'global save validates first, preserves unrelated values, and inverts updates',
    () {
      final root = tempDirs.create();
      final configPath = path.join(root.path, 'config.json');
      final lastUpdate = DateTime.utc(2026, 8, 1);
      LocalAppConfig(
        cachePath: '/old/cache',
        gitCachePath: '/old/git',
        flutterUrl: 'https://example.com/flutter.git',
        useGitCache: true,
        privilegedAccess: false,
        runPubGetOnSdkChanges: false,
        updateVscodeSettings: false,
        updateGitIgnore: false,
        updateMelosSettings: false,
        disableUpdateCheck: true,
        lastUpdateCheck: lastUpdate,
        forks: {
          const FlutterFork(name: 'team', url: 'https://example.com/team'),
        },
      ).save(path: configPath);
      final context = FvmContext.create(
        isTest: true,
        workingDirectoryOverride: root.path,
        appConfigPath: configPath,
      );

      final snapshot = ConfigurationService(context).save(
        ConfigurationTarget.global,
        _patch(cachePath: '/new/cache', updateCheckEnabled: true),
      );
      final persisted = LocalAppConfig.read(
        path: configPath,
        requireValid: true,
      );

      expect(snapshot.cachePath, '/new/cache');
      expect(snapshot.updateCheckEnabled, isTrue);
      expect(persisted.disableUpdateCheck, isFalse);
      expect(persisted.flutterUrl, 'https://example.com/flutter.git');
      expect(persisted.useGitCache, isTrue);
      expect(persisted.privilegedAccess, isFalse);
      expect(persisted.lastUpdateCheck, lastUpdate);
      expect(persisted.forks.single.name, 'team');
    },
  );

  test('global malformed input fails before writing', () {
    final root = tempDirs.create();
    final configPath = path.join(root.path, 'config.json');
    const malformed = '{"cachePath":';
    final file = File(configPath)..writeAsStringSync(malformed);
    final context = FvmContext.create(
      isTest: true,
      workingDirectoryOverride: root.path,
      appConfigPath: configPath,
    );

    expect(
      () => ConfigurationService(
        context,
      ).save(ConfigurationTarget.global, _patch(cachePath: '/new/cache')),
      throwsA(isA<AppException>()),
    );
    expect(file.readAsStringSync(), malformed);
  });

  test(
    'project snapshots expose explicit keys and preserve Flutter settings',
    () {
      final root = tempDirs.create();
      createPubspecYaml(root);
      createProjectConfig(
        const ProjectConfig(
          flutter: '3.35.1',
          flavors: {'production': '3.35.1'},
          useGitCache: false,
          updateVscodeSettings: false,
        ),
        root,
      );
      final context = FvmContext.create(
        isTest: true,
        workingDirectoryOverride: root.path,
        configOverrides: const AppConfig(
          cachePath: '/inherited/cache',
          gitCachePath: '/inherited/git',
          runPubGetOnSdkChanges: true,
          updateGitIgnore: true,
          updateMelosSettings: true,
        ),
      );
      final service = ConfigurationService(context);

      final before = service.read(ConfigurationTarget.project);
      final after = service.save(
        ConfigurationTarget.project,
        _patch(cachePath: '/project/cache', updateMelosSettings: false),
      );
      final project = Project.loadFromDirectory(root);

      expect(before.updateCheckEnabled, isNull);
      expect(before.overriddenSettings, {
        ConfigurationSetting.useGitCache,
        ConfigurationSetting.updateVscodeSettings,
      });
      expect(after.cachePath, '/project/cache');
      expect(after.updateMelosSettings, isFalse);
      expect(
        after.overriddenSettings,
        contains(ConfigurationSetting.cachePath),
      );
      expect(project.config!.flutter, '3.35.1');
      expect(project.config!.flavors, {'production': '3.35.1'});
      expect(project.config!.updateVscodeSettings, isFalse);
      expect(project.config!.useGitCache, isFalse);
    },
  );

  test('project save rejects global-only update checking without writing', () {
    final root = tempDirs.create();
    createPubspecYaml(root);
    final configFile = createProjectConfig(
      const ProjectConfig(flutter: '3.35.1'),
      root,
    );
    final before = configFile.readAsStringSync();
    final context = FvmContext.create(
      isTest: true,
      workingDirectoryOverride: root.path,
    );

    expect(
      () => ConfigurationService(
        context,
      ).save(ConfigurationTarget.project, _patch(updateCheckEnabled: false)),
      throwsA(isA<AppException>()),
    );
    expect(configFile.readAsStringSync(), before);
  });
}

ConfigurationPatch _patch({
  String? cachePath,
  String? gitCachePath,
  String? flutterUrl,
  bool? runPubGetOnSdkChanges,
  bool? updateVscodeSettings,
  bool? updateGitIgnore,
  bool? updateMelosSettings,
  bool? useGitCache,
  bool? updateCheckEnabled,
}) => (
  cachePath: cachePath,
  gitCachePath: gitCachePath,
  flutterUrl: flutterUrl,
  runPubGetOnSdkChanges: runPubGetOnSdkChanges,
  updateVscodeSettings: updateVscodeSettings,
  updateGitIgnore: updateGitIgnore,
  updateMelosSettings: updateMelosSettings,
  useGitCache: useGitCache,
  updateCheckEnabled: updateCheckEnabled,
);
