import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Git cache auto-migration', () {
    late Directory tempDir;
    late Directory remoteDir;
    late FvmContext context;
    late GitService gitService;
    late List<CacheFlutterVersion> installedVersions;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('fvm_git_cache_test_');

      remoteDir = await createLocalRemoteRepository(
        root: tempDir,
        name: 'flutter_remote',
      );

      installedVersions = [];

      context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, '.fvm'),
          gitCachePath: p.join(tempDir.path, 'cache.git'),
          flutterUrl: remoteDir.path,
          useGitCache: true,
        ),
        generatorsOverride: {
          CacheService: (ctx) =>
              _StubCacheService(ctx, () => installedVersions),
        },
      );

      gitService = GitService(context);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'migrates working-tree cache to bare mirror and detaches alternates',
      () async {
        Directory(context.gitCachePath).parent.createSync(recursive: true);
        await runGitCommand(['clone', remoteDir.path, context.gitCachePath]);

        final versionDir = Directory(
          p.join(context.versionsCachePath, 'master'),
        );
        versionDir.parent.createSync(recursive: true);

        await runGitCommand([
          'clone',
          '--reference',
          context.gitCachePath,
          remoteDir.path,
          versionDir.path,
        ]);

        final version = FlutterVersion.parse('master');
        installedVersions.add(
          CacheFlutterVersion.fromVersion(version, directory: versionDir.path),
        );

        final alternatesFile = File(
          p.join(
            versionDir.path,
            '.git',
            'objects',
            'info',
            'alternates',
          ),
        );
        expect(alternatesFile.existsSync(), isTrue);

        await gitService.updateLocalMirror();

        expect(await isBareGitRepository(context.gitCachePath), isTrue);
        expect(alternatesFile.existsSync(), isFalse);

        final legacyArtifacts = Directory(context.gitCachePath)
            .parent
            .listSync()
            .where((entity) => entity.path.contains('.legacy-'));
        expect(legacyArtifacts, isEmpty);
      },
    );
  });
}

class _StubCacheService extends CacheService {
  _StubCacheService(super.context, this._versionsProvider);

  final List<CacheFlutterVersion> Function() _versionsProvider;

  @override
  Future<List<CacheFlutterVersion>> getAllVersions() async {
    return _versionsProvider();
  }
}
