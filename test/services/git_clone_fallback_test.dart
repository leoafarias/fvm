import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

Future<List<String>> _gitRefs(String repoPath) async {
  final result = await runGitCommand(
    ['for-each-ref', '--format=%(refname)'],
    workingDirectory: repoPath,
  );

  return result.stdout
      .toString()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

void main() {
  group('Git cache auto-migration', () {
    late Directory tempDir;
    late Directory remoteDir;
    late FvmContext context;
    late GitService gitService;
    late List<CacheFlutterVersion> installedVersions;
    late bool failSdkRemoval;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('fvm_git_cache_test_');

      remoteDir = await createLocalRemoteRepository(
        root: tempDir,
        name: 'flutter_remote',
      );

      installedVersions = [];
      failSdkRemoval = false;

      context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, '.fvm'),
          gitCachePath: p.join(tempDir.path, 'cache.git'),
          flutterUrl: Uri.file(remoteDir.path).toString(),
          useGitCache: true,
        ),
        generatorsOverride: {
          CacheService: (ctx) => _StubCacheService(
                ctx,
                () => installedVersions,
                shouldFailRemove: () => failSdkRemoval,
              ),
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
      'migrates working-tree cache to heads/tags cache and dissociates SDK',
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

        // After migration, the cache should be bare
        expect(await isBareGitRepository(context.gitCachePath), isTrue);

        final refs = await _gitRefs(context.gitCachePath);
        expect(
          refs.every(
            (ref) =>
                ref.startsWith('refs/heads/') || ref.startsWith('refs/tags/'),
          ),
          isTrue,
        );

        // FVM-owned alternates are removed after objects are repacked locally.
        expect(alternatesFile.existsSync(), isFalse);
        await runGitCommand(
          ['fsck', '--connectivity-only'],
          workingDirectory: versionDir.path,
        );

        final legacyArtifacts = Directory(context.gitCachePath)
            .parent
            .listSync()
            .where((entity) => entity.path.contains('.legacy-'));
        expect(legacyArtifacts, isEmpty);
      },
    );

    test(
      'does not remove alternates that point outside cache path boundary',
      () async {
        Directory(context.gitCachePath).parent.createSync(recursive: true);
        await runGitCommand(['clone', remoteDir.path, context.gitCachePath]);

        final versionDir = Directory(
          p.join(context.versionsCachePath, 'stable'),
        );
        versionDir.createSync(recursive: true);

        final alternatesFile = File(
          p.join(
            versionDir.path,
            '.git',
            'objects',
            'info',
            'alternates',
          ),
        )..createSync(recursive: true);

        final backupObjectsPath = p.join(
          '${context.gitCachePath}.backup-custom',
          'objects',
        );
        alternatesFile.writeAsStringSync('$backupObjectsPath\n');

        installedVersions.add(
          CacheFlutterVersion.fromVersion(
            FlutterVersion.parse('stable'),
            directory: versionDir.path,
          ),
        );

        await gitService.updateLocalMirror();

        expect(
          alternatesFile.readAsStringSync().trim(),
          equals(backupObjectsPath),
        );
      },
    );

    test(
      'removes only FVM-owned entries from multi-line alternates file',
      () async {
        Directory(context.gitCachePath).parent.createSync(recursive: true);
        await runGitCommand(['clone', remoteDir.path, context.gitCachePath]);

        final versionDir = Directory(
          p.join(context.versionsCachePath, 'beta'),
        );
        versionDir.parent.createSync(recursive: true);

        await runGitCommand([
          'clone',
          '--reference',
          context.gitCachePath,
          remoteDir.path,
          versionDir.path,
        ]);

        final externalRepo = Directory(p.join(tempDir.path, 'external.git'));
        await runGitCommand(['init', '--bare', externalRepo.path]);
        final externalObjectsPath = p.join(externalRepo.path, 'objects');

        final alternatesFile = File(
          p.join(
            versionDir.path,
            '.git',
            'objects',
            'info',
            'alternates',
          ),
        );
        final fvmAlternateLine = alternatesFile.readAsStringSync().trim();
        final relativeFvmAlternateLine = p.relative(
          fvmAlternateLine,
          from: p.join(versionDir.path, '.git', 'objects'),
        );
        alternatesFile.writeAsStringSync(
          '$relativeFvmAlternateLine\n$externalObjectsPath\n',
        );

        installedVersions.add(
          CacheFlutterVersion.fromVersion(
            FlutterVersion.parse('beta'),
            directory: versionDir.path,
          ),
        );

        await gitService.updateLocalMirror();

        expect(alternatesFile.existsSync(), isTrue);
        final retainedLines = alternatesFile
            .readAsLinesSync()
            .where((line) => line.trim().isNotEmpty)
            .toList();
        expect(retainedLines, equals([externalObjectsPath]));
        expect(
          retainedLines.any((line) => line.contains(context.gitCachePath)),
          isFalse,
        );
        await runGitCommand(
          ['fsck', '--connectivity-only'],
          workingDirectory: versionDir.path,
        );
      },
    );

    test(
      'removes affected SDK when FVM-owned alternates cannot be dissociated',
      () async {
        Directory(context.gitCachePath).parent.createSync(recursive: true);
        await runGitCommand(['clone', remoteDir.path, context.gitCachePath]);

        final brokenVersionDir = Directory(
          p.join(context.versionsCachePath, 'broken'),
        );
        final alternatesFile = File(
          p.join(
            brokenVersionDir.path,
            '.git',
            'objects',
            'info',
            'alternates',
          ),
        )..createSync(recursive: true);

        final fvmObjectsPath = p.join(context.gitCachePath, '.git', 'objects');
        alternatesFile.writeAsStringSync('$fvmObjectsPath\n');

        installedVersions.add(
          CacheFlutterVersion.fromVersion(
            FlutterVersion.parse('broken'),
            directory: brokenVersionDir.path,
          ),
        );

        await gitService.updateLocalMirror();

        expect(await isBareGitRepository(context.gitCachePath), isTrue);
        expect(brokenVersionDir.existsSync(), isFalse);
      },
    );

    test(
      'aborts cache replacement when affected SDK cannot be removed',
      () async {
        Directory(context.gitCachePath).parent.createSync(recursive: true);
        await runGitCommand(['clone', remoteDir.path, context.gitCachePath]);

        final brokenVersionDir = Directory(
          p.join(context.versionsCachePath, 'blocked'),
        );
        final alternatesFile = File(
          p.join(
            brokenVersionDir.path,
            '.git',
            'objects',
            'info',
            'alternates',
          ),
        )..createSync(recursive: true);

        final fvmObjectsPath = p.join(context.gitCachePath, '.git', 'objects');
        alternatesFile.writeAsStringSync('$fvmObjectsPath\n');

        installedVersions.add(
          CacheFlutterVersion.fromVersion(
            FlutterVersion.parse('blocked'),
            directory: brokenVersionDir.path,
          ),
        );
        failSdkRemoval = true;

        await expectLater(
          EnsureCacheWorkflow(context).call(
            FlutterVersion.parse('master'),
            shouldInstall: true,
          ),
          throwsA(isA<GitCacheDependentSdkRemovalException>()),
        );

        expect(await isBareGitRepository(context.gitCachePath), isFalse);
        expect(brokenVersionDir.existsSync(), isTrue);
        final tempCacheDirs = Directory(context.gitCachePath)
            .parent
            .listSync()
            .whereType<Directory>()
            .where(
              (dir) => p
                  .basename(dir.path)
                  .startsWith('${p.basename(context.gitCachePath)}.'),
            )
            .toList();
        expect(tempCacheDirs, isEmpty);
      },
    );

    test(
      'removes affected SDK when alternates file cannot be read',
      () async {
        Directory(context.gitCachePath).parent.createSync(recursive: true);
        await runGitCommand(['clone', remoteDir.path, context.gitCachePath]);

        final brokenVersionDir = Directory(
          p.join(context.versionsCachePath, 'unreadable'),
        );
        final alternatesFile = File(
          p.join(
            brokenVersionDir.path,
            '.git',
            'objects',
            'info',
            'alternates',
          ),
        )..createSync(recursive: true);

        final fvmObjectsPath = p.join(context.gitCachePath, '.git', 'objects');
        alternatesFile.writeAsStringSync('$fvmObjectsPath\n');
        await Process.run('chmod', ['000', alternatesFile.path]);

        installedVersions.add(
          CacheFlutterVersion.fromVersion(
            FlutterVersion.parse('unreadable'),
            directory: brokenVersionDir.path,
          ),
        );

        await gitService.updateLocalMirror();

        await Process.run('chmod', ['600', alternatesFile.path]);
        expect(await isBareGitRepository(context.gitCachePath), isTrue);
        expect(brokenVersionDir.existsSync(), isFalse);
      },
      skip: Platform.isWindows ? 'POSIX file permissions required' : false,
    );
  });
}

class _StubCacheService extends CacheService {
  _StubCacheService(
    super.context,
    this._versionsProvider, {
    required bool Function() shouldFailRemove,
  }) : _shouldFailRemove = shouldFailRemove;

  final List<CacheFlutterVersion> Function() _versionsProvider;
  final bool Function() _shouldFailRemove;

  @override
  Future<List<CacheFlutterVersion>> getAllVersions() async {
    return _versionsProvider();
  }

  @override
  Future<void> remove(FlutterVersion version) async {
    if (_shouldFailRemove()) {
      throw const FileSystemException('blocked by test');
    }

    return super.remove(version);
  }
}
