import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/cleanup_service.dart';
import 'package:fvm/src/services/project_registry_service.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('CleanupService', () {
    test(
      'plans cached patch upgrades with project and global actions',
      () async {
        final primary = createConfiguredProject(
          name: 'primary',
          flutter: '3.10.0',
        );
        final flavored = createConfiguredProject(
          name: 'flavored',
          flutter: 'stable',
          flavors: const {'legacy': '3.10.0'},
        );
        final context = TestFactory.fastContext();
        FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
        final latest = FakeFlutterSdkFixture.install(
          context,
          FlutterVersion.parse('3.10.5'),
        );
        FakeFlutterSdkFixture.install(context, FlutterVersion.parse('beta'));
        final registry = context.get<ProjectRegistryService>()
          ..track(Project.loadFromDirectory(primary))
          ..track(Project.loadFromDirectory(flavored));
        expect(registry.calculateUsage().countFor('3.10.0'), 2);
        context.get<CacheService>().setGlobal(
              context.get<CacheService>().getVersion(
                    FlutterVersion.parse('3.10.0'),
                  )!,
            );

        final plan = await context.get<CleanupService>().plan();

        final upgrade = plan.upgrades.singleWhere(
          (item) => item.fromVersion == '3.10.0',
        );
        expect(upgrade.toVersion, '3.10.5');
        expect(
          upgrade.actions.map((action) => action.arguments.first),
          containsAll(['global', 'use']),
        );
        expect(
          upgrade.actions.map((action) => action.workingDirectory),
          containsAll([
            primary.resolveSymbolicLinksSync(),
            flavored.resolveSymbolicLinksSync(),
          ]),
        );
        expect(
          upgrade.actions.any(
            (action) =>
                action.arguments.join(' ') == 'use 3.10.5 --flavor legacy',
          ),
          isTrue,
        );
        expect(plan.unused, isNot(contains(latest.nameWithAlias)));
        expect(plan.unused, contains('beta'));
      },
    );

    test('does not recommend patch upgrades across minor lines', () async {
      final project = createConfiguredProject(name: 'minor', flutter: '3.10.0');
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.19.0'));
      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(project),
          );

      final plan = await context.get<CleanupService>().plan();

      expect(plan.upgrades, isEmpty);
    });

    test('does not recommend patch upgrades across forks', () async {
      final project = createConfiguredProject(
        name: 'forked_line',
        flutter: 'myfork/3.10.0',
      );
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('myfork/3.10.0'),
      );
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.5'));
      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(project),
          );

      final plan = await context.get<CleanupService>().plan();

      expect(plan.upgrades, isEmpty);
    });

    test('does not recommend patch upgrades for channel-qualified releases',
        () async {
      final project = createConfiguredProject(
        name: 'channel_pin',
        flutter: '3.10.0@beta',
      );
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('3.10.0@beta'),
      );
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('3.10.5@beta'),
      );
      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(project),
          );

      final plan = await context.get<CleanupService>().plan();

      expect(plan.upgrades, isEmpty);
    });

    test('removes unused older patches but keeps the upgrade target', () async {
      final project = createConfiguredProject(
        name: 'keep_target',
        flutter: '3.10.0',
      );
      final context = TestFactory.fastContext();
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.0'));
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.1'));
      FakeFlutterSdkFixture.install(context, FlutterVersion.parse('3.10.5'));
      context.get<ProjectRegistryService>().track(
            Project.loadFromDirectory(project),
          );

      final plan = await context.get<CleanupService>().plan();

      expect(
        plan.upgrades.where((upgrade) => upgrade.fromVersion == '3.10.0'),
        hasLength(1),
      );
      expect(plan.unused, contains('3.10.1'));
      expect(plan.unused, isNot(contains('3.10.5')));
    });
  });
}
