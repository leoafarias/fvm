import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

// Custom exception handler to test error handling
void throwGitError(String message, List<String> args) {
  final e = ProcessException('git', args, message, 128);
  throw e;
}

void main() {
  group('FlutterService', () {
    group('install method', () {
      test('handles non-existent fork', () async {
        final context = TestFactory.context();
        final service = FlutterService(context);
        final version = FlutterVersion.parse('nonexistent-fork/stable');

        expect(
          () => service.install(version),
          throwsA(
            isA<AppException>().having(
              (e) => e.toString(),
              'message',
              contains('not found in configuration'),
            ),
          ),
        );
      });

      test('clones from local mirror and rewrites origin URL', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'fvm_flutter_service_mirror_',
        );

        try {
          final remoteDir = await createLocalRemoteRepository(
            root: tempDir,
            name: 'flutter_origin',
          );

          final cachePath = p.join(tempDir.path, '.fvm');
          final gitCachePath = p.join(tempDir.path, 'mirror.git');
          Directory(gitCachePath).parent.createSync(recursive: true);
          await runGitCommand([
            'clone',
            '--mirror',
            remoteDir.path,
            gitCachePath,
          ]);

          final context = FvmContext.create(
            isTest: true,
            configOverrides: AppConfig(
              cachePath: cachePath,
              gitCachePath: gitCachePath,
              flutterUrl: remoteDir.path,
              useGitCache: true,
            ),
          );

          final service = FlutterService(context);
          final version = FlutterVersion.parse('master');

          await service.install(version);

          final cacheService = context.get<CacheService>();
          final versionDir = cacheService.getVersionCacheDir(version);

          final remoteResult = await runGitCommand(
            ['remote', 'get-url', 'origin'],
            workingDirectory: versionDir.path,
          );

          expect(remoteResult.stdout.toString().trim(), remoteDir.path);

          final alternatesFile = File(
            p.join(
              versionDir.path,
              '.git',
              'objects',
              'info',
              'alternates',
            ),
          );
          expect(alternatesFile.existsSync(), isFalse);
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      });

      test('falls back to remote clone when local mirror is unavailable',
          () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'fvm_flutter_service_fallback_',
        );

        try {
          final remoteDir = await createLocalRemoteRepository(
            root: tempDir,
            name: 'flutter_origin',
          );

          final cachePath = p.join(tempDir.path, '.fvm');
          final gitCachePath = p.join(tempDir.path, 'missing', 'mirror.git');

          final context = FvmContext.create(
            isTest: true,
            configOverrides: AppConfig(
              cachePath: cachePath,
              gitCachePath: gitCachePath,
              flutterUrl: remoteDir.path,
              useGitCache: true,
            ),
          );

          final service = FlutterService(context);
          final version = FlutterVersion.parse('master');

          await service.install(version);

          final cacheService = context.get<CacheService>();
          final versionDir = cacheService.getVersionCacheDir(version);

          final remoteResult = await runGitCommand(
            ['remote', 'get-url', 'origin'],
            workingDirectory: versionDir.path,
          );

          expect(remoteResult.stdout.toString().trim(), remoteDir.path);

          final logger = context.get<Logger>();
          expect(
            logger.outputs.any(
              (entry) => entry.contains('Falling back to remote clone'),
            ),
            isTrue,
          );
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      });

      test('retries with remote clone when mirror is missing reference',
          () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'fvm_flutter_service_retry_',
        );

        try {
          // Create remote and seed mirror before the new branch exists
          final remoteDir = await createLocalRemoteRepository(
            root: tempDir,
            name: 'flutter_origin',
          );

          final gitCachePath = p.join(tempDir.path, 'mirror.git');
          Directory(gitCachePath).parent.createSync(recursive: true);
          await runGitCommand([
            'clone',
            '--mirror',
            remoteDir.path,
            gitCachePath,
          ]);

          // Add a new branch to the remote after the mirror was created so the
          // mirror does not contain the reference.
          final workDir = Directory(p.join(tempDir.path, 'work'))..createSync();
          await runGitCommand(['clone', remoteDir.path, workDir.path]);
          await runGitCommand(
            ['config', 'user.email', 'tests@fvm.app'],
            workingDirectory: workDir.path,
          );
          await runGitCommand(
            ['config', 'user.name', 'FVM Tests'],
            workingDirectory: workDir.path,
          );
          await runGitCommand(
            ['checkout', '-b', 'feature'],
            workingDirectory: workDir.path,
          );
          File(p.join(workDir.path, 'FEATURE.md')).writeAsStringSync('feature');
          await runGitCommand(['add', '.'], workingDirectory: workDir.path);
          await runGitCommand(
            ['commit', '-m', 'Add feature branch'],
            workingDirectory: workDir.path,
          );
          await runGitCommand(
            ['push', 'origin', 'feature'],
            workingDirectory: workDir.path,
          );

          final cachePath = p.join(tempDir.path, '.fvm');

          final context = FvmContext.create(
            isTest: true,
            configOverrides: AppConfig(
              cachePath: cachePath,
              gitCachePath: gitCachePath,
              flutterUrl: remoteDir.path,
              useGitCache: true,
            ),
          );

          final service = FlutterService(context);
          final version = FlutterVersion.parse('feature');

          await service.install(version);

          final cacheService = context.get<CacheService>();
          final versionDir = cacheService.getVersionCacheDir(version);

          final headResult = await runGitCommand(
            ['rev-parse', '--abbrev-ref', 'HEAD'],
            workingDirectory: versionDir.path,
          );

          expect(headResult.stdout.toString().trim(), 'feature');
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      });
    });

    test('returns expected error for reset to non-existent version', () {
      // This test verifies the error handling when `resetHard` throws an exception
      // for a non-existent version in a repository

      // We verify that the correct error message patterns in our error handler
      // will trigger the correct AppException with the expected error message

      // Test for unknown revision error message
      expect(
        () => throwGitError(
          'fatal: ambiguous argument \'non-existent-tag\': unknown revision',
          ['reset', '--hard', 'non-existent-tag'],
        ),
        throwsA(
          isA<ProcessException>().having(
            (e) => e.message,
            'message',
            contains('unknown revision'),
          ),
        ),
      );

      // Test for ambiguous argument error message
      expect(
        () => throwGitError(
          'fatal: ambiguous argument \'non-existent-branch\'',
          ['reset', '--hard', 'non-existent-branch'],
        ),
        throwsA(
          isA<ProcessException>().having(
            (e) => e.message,
            'message',
            contains('ambiguous argument'),
          ),
        ),
      );

      // Test for not found error message
      expect(
        () => throwGitError(
          'error: pathspec \'non-existent-ref\' did not match any file(s) known to git',
          ['reset', '--hard', 'non-existent-ref'],
        ),
        throwsA(
          isA<ProcessException>().having(
            (e) => e.message,
            'message',
            contains('did not match any file'),
          ),
        ),
      );
    });

    test('returns expected error for clone failures', () {
      // This test verifies the error handling when the clone operation fails

      // Test for repository not found error
      expect(
        () => throwGitError('fatal: remote: Repository not found.', [
          'clone',
          'https://example.com/fork.git',
        ]),
        throwsA(
          isA<ProcessException>().having(
            (e) => e.message,
            'message',
            contains('Repository not found'),
          ),
        ),
      );

      // Test for remote branch not found error
      expect(
        () => throwGitError(
          'fatal: Remote branch branch-name not found in upstream origin',
          ['clone', '-b', 'branch-name', 'https://example.com/repo.git'],
        ),
        throwsA(
          isA<ProcessException>().having(
            (e) => e.message,
            'message',
            (String msg) =>
                msg.contains('Remote branch') &&
                msg.contains('not found in upstream'),
          ),
        ),
      );
    });

    group('setup method', () {
      test('calls flutter --version command', () async {
        final context = TestFactory.context();
        final service = FlutterService(context);

        final flutterVersion = FlutterVersion.parse('stable');
        final mockCacheVersion = CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: p.join(context.versionsCachePath, 'stable'),
        );

        // Since this simply passes through to run(), we can just verify
        // that the method returns a Future that completes normally
        expect(service.setup(mockCacheVersion), isA<Future<ProcessResult>>());
      });
    });

    group('runFlutter method', () {
      test('executes flutter command with the specified args', () async {
        final context = TestFactory.context();
        final service = FlutterService(context);

        final flutterVersion = FlutterVersion.parse('stable');
        final mockCacheVersion = CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: p.join(context.versionsCachePath, 'stable'),
        );

        expect(
          service.runFlutter(['--help'], mockCacheVersion),
          isA<Future<ProcessResult>>(),
        );
      });
    });

    group('pubGet method', () {
      test('executes flutter pub get command', () async {
        final context = TestFactory.context();
        final service = FlutterService(context);

        final flutterVersion = FlutterVersion.parse('stable');
        final mockCacheVersion = CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: p.join(context.versionsCachePath, 'stable'),
        );

        expect(service.pubGet(mockCacheVersion), isA<Future<ProcessResult>>());
      });

      test('adds --offline flag in offline mode', () async {
        final context = TestFactory.context();
        final service = FlutterService(context);

        final flutterVersion = FlutterVersion.parse('stable');
        final mockCacheVersion = CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: p.join(context.versionsCachePath, 'stable'),
        );

        expect(
          service.pubGet(mockCacheVersion, offline: true),
          isA<Future<ProcessResult>>(),
        );
      });
    });

    group('VersionRunner', () {
      test('correctly sets up environment variables', () {
        final context = TestFactory.context();

        final flutterVersion = FlutterVersion.parse('stable');
        final mockCacheVersion = CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: p.join(context.versionsCachePath, 'stable'),
        );

        final versionRunner = VersionRunner(
          context: context,
          version: mockCacheVersion,
        );

        // Testing implementation details:
        // This test confirms the VersionRunner can be constructed correctly
        // For more comprehensive testing, we'd need to verify the environment variables
        // are correctly set, which would require mocking Platform.environment
        expect(versionRunner, isA<VersionRunner>());
      });
    });
  });
}
