import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

/// Deletes a loose git object to simulate corrupted mirrors in tests.
/// If the object is packed, it unpacks first, then deletes the loose object.
Future<void> _deleteLooseGitObject({
  required String repoPath,
  required String objectSha,
}) async {
  final objectFile = File(
    p.join(
      repoPath,
      'objects',
      objectSha.substring(0, 2),
      objectSha.substring(2),
    ),
  );

  if (!objectFile.existsSync()) {
    final packDir = Directory(p.join(repoPath, 'objects', 'pack'));
    if (packDir.existsSync()) {
      final packFiles = packDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.pack'))
          .toList();

      for (final pack in packFiles) {
        final process = await Process.start(
          'git',
          ['unpack-objects'],
          workingDirectory: repoPath,
          runInShell: true,
        );
        await pack.openRead().pipe(process.stdin);
        final exitCode = await process.exitCode;
        if (exitCode != 0) {
          throw Exception('Failed to unpack git objects from ${pack.path}');
        }
      }
    }
  }

  if (!objectFile.existsSync()) {
    throw Exception('Expected loose git object at ${objectFile.path}');
  }

  if (Platform.isWindows) {
    await Process.run(
      'attrib',
      ['-R', objectFile.path],
      runInShell: true,
    );
  }

  final attempts = Platform.isWindows ? 3 : 1;
  for (var attempt = 1; attempt <= attempts; attempt++) {
    try {
      objectFile.deleteSync();
      return;
    } on FileSystemException {
      if (!Platform.isWindows || attempt == attempts) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
    }
  }
}

class _FakeProcessService extends ProcessService {
  _FakeProcessService(super.context);

  ProcessException? exception;
  ProcessResult nextResult = ProcessResult(0, 0, '', '');
  String? lastCommand;
  List<String>? lastArgs;
  String? lastWorkingDirectory;
  Map<String, String>? lastEnvironment;
  bool? lastThrowOnError;
  bool? lastEchoOutput;

  @override
  Future<ProcessResult> run(
    String command, {
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool echoOutput = false,
    bool runInShell = true,
  }) async {
    lastCommand = command;
    lastArgs = args;
    lastWorkingDirectory = workingDirectory;
    lastEnvironment = environment;
    lastThrowOnError = throwOnError;
    lastEchoOutput = echoOutput;

    if (exception != null) {
      throw exception!;
    }

    return nextResult;
  }
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

      test('preserves reference lookup errors from install flow', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'fvm_flutter_service_reference_error_',
        );

        try {
          final remoteDir = await createLocalRemoteRepository(
            root: tempDir,
            name: 'flutter_origin',
          );

          final context = FvmContext.create(
            isTest: true,
            configOverrides: AppConfig(
              cachePath: p.join(tempDir.path, '.fvm'),
              flutterUrl: remoteDir.path,
              useGitCache: false,
            ),
          );

          final service = FlutterService(context);
          final version = FlutterVersion.parse('does-not-exist-1234');

          await expectLater(
            service.install(version),
            throwsA(
              isA<AppException>().having(
                (e) => e.message,
                'message',
                allOf(
                  contains(
                    'Reference "${version.version}" was not found in the Flutter repository.',
                  ),
                  contains('Repository URL: ${remoteDir.path}'),
                ),
              ),
            ),
          );
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      });

      test(
          'preserves reference lookup errors after retrying from mirror to remote',
          () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'fvm_flutter_service_reference_error_mirror_',
        );

        try {
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

          final context = FvmContext.create(
            isTest: true,
            configOverrides: AppConfig(
              cachePath: p.join(tempDir.path, '.fvm'),
              gitCachePath: gitCachePath,
              flutterUrl: remoteDir.path,
              useGitCache: true,
            ),
          );

          final service = FlutterService(context);
          final version = FlutterVersion.parse('does-not-exist-1234');

          await expectLater(
            service.install(version),
            throwsA(
              isA<AppException>().having(
                (e) => e.message,
                'message',
                allOf(
                  contains(
                    'Reference "${version.version}" was not found in the Flutter repository.',
                  ),
                  contains('Repository URL: ${remoteDir.path}'),
                ),
              ),
            ),
          );
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
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

      test('falls back to remote when mirror has missing objects', () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'fvm_flutter_service_missing_objects_',
        );

        try {
          final remoteDir = await createLocalRemoteRepository(
            root: tempDir,
            name: 'flutter_origin',
          );

          // Create a feature branch in the remote.
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

          final gitCachePath = p.join(tempDir.path, 'mirror.git');
          Directory(gitCachePath).parent.createSync(recursive: true);
          await runGitCommand([
            'clone',
            '--mirror',
            remoteDir.path,
            gitCachePath,
          ]);

          final featureShaResult = await runGitCommand(
            ['rev-parse', 'feature'],
            workingDirectory: gitCachePath,
          );
          final featureSha = featureShaResult.stdout.toString().trim();
          await _deleteLooseGitObject(
            repoPath: gitCachePath,
            objectSha: featureSha,
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

    group('setup method', () {
      test('calls flutter --version command', () async {
        late _FakeProcessService processService;
        final context = TestFactory.context(
          generators: {
            ProcessService: (ctx) {
              processService = _FakeProcessService(ctx);
              return processService;
            },
          },
        );
        final service = FlutterService(context);

        final flutterVersion = FlutterVersion.parse('stable');
        final mockCacheVersion = CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: p.join(context.versionsCachePath, 'stable'),
        );

        final result = await service.setup(mockCacheVersion);

        expect(result.exitCode, equals(0));
        expect(processService.lastCommand, equals('flutter'));
        expect(processService.lastArgs, equals(['--version']));
        expect(processService.lastWorkingDirectory, isNull);
        expect(processService.lastThrowOnError, isFalse);
        expect(processService.lastEchoOutput, isTrue);
        final pathValue = processService.lastEnvironment?['PATH'];
        expect(pathValue, isNotNull);
        expect(pathValue, contains(mockCacheVersion.binPath));
        expect(pathValue, contains(mockCacheVersion.dartBinPath));
      });
    });

    group('runFlutter method', () {
      test('executes flutter command with the specified args', () async {
        late _FakeProcessService processService;
        final context = TestFactory.context(
          generators: {
            ProcessService: (ctx) {
              processService = _FakeProcessService(ctx);
              return processService;
            },
          },
        );
        final service = FlutterService(context);

        final flutterVersion = FlutterVersion.parse('stable');
        final mockCacheVersion = CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: p.join(context.versionsCachePath, 'stable'),
        );

        final result = await service.runFlutter(['--help'], mockCacheVersion);

        expect(result.exitCode, equals(0));
        expect(processService.lastCommand, equals('flutter'));
        expect(processService.lastArgs, equals(['--help']));
        expect(processService.lastWorkingDirectory, isNull);
        expect(processService.lastThrowOnError, isFalse);
        expect(processService.lastEchoOutput, isTrue);
        final pathValue = processService.lastEnvironment?['PATH'];
        expect(pathValue, isNotNull);
        expect(pathValue, contains(mockCacheVersion.binPath));
        expect(pathValue, contains(mockCacheVersion.dartBinPath));
      });
    });

    group('pubGet method', () {
      test('executes flutter pub get command', () async {
        late _FakeProcessService processService;
        final context = TestFactory.context(
          generators: {
            ProcessService: (ctx) {
              processService = _FakeProcessService(ctx);
              return processService;
            },
          },
        );
        final service = FlutterService(context);

        final flutterVersion = FlutterVersion.parse('stable');
        final mockCacheVersion = CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: p.join(context.versionsCachePath, 'stable'),
        );

        final result = await service.pubGet(mockCacheVersion);

        expect(result.exitCode, equals(0));
        expect(processService.lastCommand, equals('flutter'));
        expect(processService.lastArgs, equals(['pub', 'get']));
        expect(processService.lastWorkingDirectory, isNull);
        expect(processService.lastThrowOnError, isFalse);
        expect(processService.lastEchoOutput, isTrue);
        final pathValue = processService.lastEnvironment?['PATH'];
        expect(pathValue, isNotNull);
        expect(pathValue, contains(mockCacheVersion.binPath));
        expect(pathValue, contains(mockCacheVersion.dartBinPath));
      });

      test('adds --offline flag in offline mode', () async {
        late _FakeProcessService processService;
        final context = TestFactory.context(
          generators: {
            ProcessService: (ctx) {
              processService = _FakeProcessService(ctx);
              return processService;
            },
          },
        );
        final service = FlutterService(context);

        final flutterVersion = FlutterVersion.parse('stable');
        final mockCacheVersion = CacheFlutterVersion.fromVersion(
          flutterVersion,
          directory: p.join(context.versionsCachePath, 'stable'),
        );

        final result = await service.pubGet(
          mockCacheVersion,
          offline: true,
        );

        expect(result.exitCode, equals(0));
        expect(processService.lastCommand, equals('flutter'));
        expect(processService.lastArgs, equals(['pub', 'get', '--offline']));
        expect(processService.lastWorkingDirectory, isNull);
        expect(processService.lastThrowOnError, isFalse);
        expect(processService.lastEchoOutput, isFalse);
        final pathValue = processService.lastEnvironment?['PATH'];
        expect(pathValue, isNotNull);
        expect(pathValue, contains(mockCacheVersion.binPath));
        expect(pathValue, contains(mockCacheVersion.dartBinPath));
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
