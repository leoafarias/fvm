import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/archive_service.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

// Mock classes
class MockFlutterReleaseClient extends Mock implements FlutterReleaseClient {}

class MockProcessService extends Mock implements ProcessService {}

class _RedirectHttpClient implements HttpClient {
  _RedirectHttpClient(this._baseUri, this._inner);

  final Uri _baseUri;
  final HttpClient _inner;

  Uri _redirect(Uri uri) {
    return uri.replace(
      scheme: _baseUri.scheme,
      host: _baseUri.host,
      port: _baseUri.port,
    );
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _inner.getUrl(_redirect(url));

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _inner.openUrl(method, _redirect(url));

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  set connectionTimeout(Duration? timeout) =>
      _inner.connectionTimeout = timeout;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RedirectHttpOverrides extends HttpOverrides {
  _RedirectHttpOverrides(this.baseUri);

  final Uri baseUri;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final inner = super.createHttpClient(context);

    return _RedirectHttpClient(baseUri, inner);
  }
}

/// An HttpClient that throws a predetermined error on every getUrl call.
class _ThrowingHttpClient implements HttpClient {
  _ThrowingHttpClient(this._error);

  final Object _error;

  @override
  Future<HttpClientRequest> getUrl(Uri url) => Future.error(_error);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.error(_error);

  @override
  void close({bool force = false}) {}

  @override
  set connectionTimeout(Duration? timeout) {}

  @override
  Duration? get connectionTimeout => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingHttpOverrides extends HttpOverrides {
  _ThrowingHttpOverrides(this.error);

  final Object error;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _ThrowingHttpClient(error);
  }
}

Future<HttpServer> _startArchiveServer({
  int statusCode = 200,
  List<int> body = const <int>[],
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

  server.listen((HttpRequest request) async {
    request.response
      ..statusCode = statusCode
      ..headers.contentLength = body.length
      ..add(body);
    await request.response.close();
  });

  return server;
}

Future<HttpServer> _startDelayedHeaderServer({
  required Duration headerDelay,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

  server.listen((HttpRequest request) async {
    try {
      await Future<void>.delayed(headerDelay);
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentLength = 0;
      await request.response.close();
    } catch (_) {
      // Ignore disconnects while intentionally delaying the response.
    }
  }, onError: (_) {});

  return server;
}

Future<HttpServer> _startStalledBodyServer({
  required Duration stallDuration,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  const firstChunk = <int>[1, 2, 3];
  const secondChunk = <int>[4, 5, 6];

  server.listen((HttpRequest request) async {
    try {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentLength = firstChunk.length + secondChunk.length
        ..add(firstChunk);
      await request.response.flush();
      await Future<void>.delayed(stallDuration);
      request.response.add(secondChunk);
      await request.response.close();
    } catch (_) {
      // Ignore disconnects while intentionally stalling the response body.
    }
  }, onError: (_) {});

  return server;
}

Directory _targetDirFromInvocation(Invocation invocation) {
  final args = invocation.namedArguments[const Symbol('args')] as List<String>;

  // Unix: unzip -q -o archive -d targetPath
  final targetIdx = args.indexOf('-d');
  if (targetIdx >= 0) return Directory(args[targetIdx + 1]);

  // Unix: tar -xJf archive -C targetPath
  final cIdx = args.indexOf('-C');
  if (cIdx >= 0) return Directory(args[cIdx + 1]);

  // Windows: powershell -Command "Expand-Archive ... -DestinationPath 'path' ..."
  final commandArg = args.last;
  final match = RegExp(r"-DestinationPath\s+'([^']+)'").firstMatch(commandArg);
  if (match != null) return Directory(match.group(1)!);

  throw StateError('Cannot determine target directory from args: $args');
}

Future<ProcessResult> _simulateExtraction(
  Invocation invocation, {
  bool createFlutterSubdir = true,
  FutureOr<void> Function(
    Directory targetDir,
    Directory sdkRootDir,
    Directory binDir,
  )? onPrepared,
}) async {
  final targetDir = _targetDirFromInvocation(invocation);
  final sdkRootDir = createFlutterSubdir
      ? Directory(path.join(targetDir.path, 'flutter'))
      : targetDir;

  sdkRootDir.createSync(recursive: true);
  final binDir = Directory(path.join(sdkRootDir.path, 'bin'))
    ..createSync(recursive: true);

  final execName = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final flutterExec = File(path.join(binDir.path, execName));
  flutterExec.writeAsStringSync('#!/bin/sh\necho mock\n');
  if (!Platform.isWindows) {
    Process.runSync('chmod', ['+x', flutterExec.path]);
  }

  if (onPrepared != null) {
    await onPrepared(targetDir, sdkRootDir, binDir);
  }

  return ProcessResult(0, 0, '', '');
}

void main() {
  late FvmContext context;
  late ArchiveService archiveService;
  late MockFlutterReleaseClient mockReleaseClient;
  late Directory tempDir;
  late List<Directory> trackedArchiveTempDirs;

  // Test fixture data
  FlutterSdkRelease createTestRelease({
    String version = '3.16.0',
    String channel = 'stable',
    String archive = 'stable/macos/flutter_macos_3.16.0-stable.zip',
    String? sha256,
  }) {
    return FlutterSdkRelease(
      hash: 'abc123',
      channel: FlutterChannel.values.firstWhere((c) => c.name == channel),
      version: version,
      releaseDate: DateTime(2024, 1, 1),
      archive: archive,
      sha256: sha256 ??
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      activeChannel: true,
      dartSdkVersion: '3.2.0',
      dartSdkArch: 'x64',
    );
  }

  setUp(() {
    registerFallbackValue(FlutterVersion.parse('stable'));
    registerFallbackValue(<String>[]);
    registerFallbackValue('command');

    mockReleaseClient = MockFlutterReleaseClient();
    trackedArchiveTempDirs = [];

    context = TestFactory.context(
      debugLabel: 'archive-service-test',
      generators: {
        FlutterReleaseClient: (_) => mockReleaseClient,
      },
    );

    tempDir = Directory(context.versionsCachePath);
    archiveService = ArchiveService(context);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<T> withArchiveTestZone<T>({
    required int port,
    required Future<T> Function(ArchiveService svc, Directory versionDir) body,
    Map<Type, Generator>? extraGenerators,
    String debugLabel = 'archive-test',
    String version = 'stable',
    Duration responseTimeout = const Duration(seconds: 30),
    Duration readTimeout = const Duration(seconds: 30),
  }) async {
    final overrides = _RedirectHttpOverrides(
      Uri.parse('http://127.0.0.1:$port'),
    );

    return HttpOverrides.runZoned(
      () async {
        final ctx = TestFactory.context(
          debugLabel: debugLabel,
          generators: {
            FlutterReleaseClient: (_) => mockReleaseClient,
            ...?extraGenerators,
          },
        );

        final svc = ArchiveService(
          ctx,
          responseTimeout: responseTimeout,
          readTimeout: readTimeout,
          createTempDir: (prefix) async {
            final dir = Directory(
              path.join(
                ctx.fvmDir,
                '$prefix${trackedArchiveTempDirs.length}',
              ),
            );
            dir.createSync(recursive: true);
            trackedArchiveTempDirs.add(dir);

            return dir;
          },
        );
        tempDir = Directory(ctx.versionsCachePath);
        final versionDir = Directory(path.join(tempDir.path, version));
        return body(svc, versionDir);
      },
      createHttpClient: overrides.createHttpClient,
    );
  }

  void expectTrackedArchiveTempDirsDeleted() {
    expect(trackedArchiveTempDirs, isNotEmpty);
    expect(
      trackedArchiveTempDirs.every((dir) => !dir.existsSync()),
      isTrue,
    );
  }

  group('ArchiveService', () {
    group('install - version validation', () {
      test('throws AppException for forked versions', () async {
        final version = FlutterVersion.parse('mycompany/stable');

        expect(
          () => archiveService.install(version, tempDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('not supported for forked Flutter SDKs'),
            ),
          ),
        );
      });

      test('throws AppException for commit references', () async {
        final version =
            FlutterVersion.parse('abc123def456789012345678901234567890abcd');

        expect(
          () => archiveService.install(version, tempDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('not supported for git references'),
            ),
          ),
        );
      });

      test('throws AppException for unsupported channels', () async {
        final version = FlutterVersion.parse('master');

        expect(
          () => archiveService.install(version, tempDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('stable, beta, or dev'),
            ),
          ),
        );
      });
    });

    group('install - release resolution', () {
      test('throws when release version not found', () async {
        final version = FlutterVersion.parse('99.99.99');

        when(() => mockReleaseClient.getReleaseByVersion('99.99.99'))
            .thenAnswer((_) async => null);

        expect(
          () => archiveService.install(version, tempDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('could not be found'),
            ),
          ),
        );
      });

      test('uses channel-specific lookup for @beta qualifiers', () async {
        final version = FlutterVersion.parse('2.2.2@beta');

        when(() => mockReleaseClient.getChannelReleases('beta')).thenAnswer(
          (_) async => [],
        );

        await expectLater(
          archiveService.install(version, tempDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('beta channel releases metadata'),
            ),
          ),
        );

        verify(() => mockReleaseClient.getChannelReleases('beta')).called(1);
        verifyNever(() => mockReleaseClient.getReleaseByVersion(any()));
      });

      test('uses channel-specific lookup for @stable qualifiers', () async {
        final version = FlutterVersion.parse('2.2.2@stable');

        when(() => mockReleaseClient.getChannelReleases('stable')).thenAnswer(
          (_) async => [],
        );

        await expectLater(
          archiveService.install(version, tempDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('stable channel releases metadata'),
            ),
          ),
        );

        verify(() => mockReleaseClient.getChannelReleases('stable')).called(1);
        verifyNever(() => mockReleaseClient.getReleaseByVersion(any()));
      });

      test('rejects unsupported release qualifiers like @master', () async {
        final version = FlutterVersion.parse('2.2.2@master');

        expect(
          () => archiveService.install(version, tempDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('@stable, @beta, and @dev'),
            ),
          ),
        );

        verifyNever(() => mockReleaseClient.getChannelReleases(any()));
        verifyNever(() => mockReleaseClient.getReleaseByVersion(any()));
      });
    });

    group('archive download and extraction failures', () {
      test('throws AppException when checksum verification fails', () async {
        final server = await _startArchiveServer(
          statusCode: HttpStatus.ok,
          body: 'mismatch-content'.codeUnits,
        );
        addTearDown(() => server.close(force: true));

        final release = createTestRelease(
          version: '3.16.0',
          archive: 'stable/macos/flutter_macos_3.16.0-stable.zip',
          sha256: ''.padRight(64, '0'),
        );

        when(() => mockReleaseClient.getReleaseByVersion('3.16.0'))
            .thenAnswer((_) async => release);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'checksum-failure',
          version: '3.16.0',
          body: (svc, versionDir) async {
            await expectLater(
              svc.install(FlutterVersion.parse('3.16.0'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('corrupted or tampered'),
                ),
              ),
            );
          },
        );
      });

      test('cleans temp directory and surfaces HTTP errors', () async {
        final server =
            await _startArchiveServer(statusCode: HttpStatus.notFound);
        addTearDown(() => server.close(force: true));

        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'http-error',
          body: (svc, versionDir) async {
            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('HTTP 404'),
                ),
              ),
            );

            expectTrackedArchiveTempDirsDeleted();
          },
        );
      });

      test('propagates extraction failures and cleans temp directory',
          () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenThrow(
          ProcessException('unzip', const [], 'boom', 1),
        );

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'extract-failure',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('Failed to extract'),
                ),
              ),
            );

            expectTrackedArchiveTempDirsDeleted();
          },
        );
      });
    });

    group('SHA256 checksum verification', () {
      test('computes checksum correctly for known content', () async {
        tempDir.createSync(recursive: true);
        final testFile = File(path.join(tempDir.path, 'test.bin'));
        // "Hello" as bytes
        final testContent = [0x48, 0x65, 0x6c, 0x6c, 0x6f];
        testFile.writeAsBytesSync(testContent);

        final digest = await sha256.bind(testFile.openRead()).first;

        // Known SHA256 of "Hello"
        expect(
          digest.toString(),
          equals(
            '185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969',
          ),
        );
      });

      test('detects content changes via checksum', () async {
        tempDir.createSync(recursive: true);
        final file1 = File(path.join(tempDir.path, 'file1.bin'));
        final file2 = File(path.join(tempDir.path, 'file2.bin'));

        file1.writeAsBytesSync([1, 2, 3]);
        file2.writeAsBytesSync([1, 2, 4]); // Different last byte

        final digest1 = await sha256.bind(file1.openRead()).first;
        final digest2 = await sha256.bind(file2.openRead()).first;

        expect(digest1.toString(), isNot(equals(digest2.toString())));
      });

      test('empty file has known checksum', () async {
        tempDir.createSync(recursive: true);
        final emptyFile = File(path.join(tempDir.path, 'empty.bin'));
        emptyFile.writeAsBytesSync([]);

        final digest = await sha256.bind(emptyFile.openRead()).first;

        // SHA256 of empty content
        expect(
          digest.toString(),
          equals(
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          ),
        );
      });
    });

    group('FlutterSdkRelease model', () {
      test('archiveUrl is constructed correctly', () {
        final release = createTestRelease(
          archive: 'stable/macos/flutter_macos_3.16.0-stable.zip',
        );

        expect(release.archiveUrl, contains('storage.googleapis.com'));
        expect(release.archiveUrl, contains('flutter_infra_release/releases/'));
        expect(
          release.archiveUrl,
          endsWith('stable/macos/flutter_macos_3.16.0-stable.zip'),
        );
      });

      test('channelName returns correct value', () {
        final stableRelease = createTestRelease(channel: 'stable');
        final betaRelease = createTestRelease(channel: 'beta');
        final devRelease = createTestRelease(channel: 'dev');

        expect(stableRelease.channelName, equals('stable'));
        expect(betaRelease.channelName, equals('beta'));
        expect(devRelease.channelName, equals('dev'));
      });

      test('sha256 is preserved', () {
        const expectedHash = 'abcdef1234567890abcdef1234567890';
        final release = createTestRelease(sha256: expectedHash);

        expect(release.sha256, equals(expectedHash));
      });

      test('release properties are accessible', () {
        final release = createTestRelease(
          version: '3.16.0',
          channel: 'stable',
        );

        expect(release.version, equals('3.16.0'));
        expect(release.channel, equals(FlutterChannel.stable));
        expect(release.hash, equals('abc123'));
        expect(release.dartSdkVersion, equals('3.2.0'));
      });
    });

    group('custom version validation', () {
      test('throws AppException for custom Flutter SDKs', () async {
        final customVersion = FlutterVersion.parse('custom_local_sdk');

        expect(
          () => archiveService.install(customVersion, tempDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('not supported for custom'),
            ),
          ),
        );
      });
    });

    group('PowerShell path escaping', () {
      test('single quotes in paths are properly escaped', () {
        // Verify the escaping logic works correctly
        // PowerShell single quotes are escaped by doubling them
        const testPath = "C:\\Users\\Test's Folder\\flutter";
        final escaped = testPath.replaceAll("'", "''");

        expect(escaped, equals("C:\\Users\\Test''s Folder\\flutter"));
      });

      test('paths without special characters are unchanged', () {
        const testPath = 'C:\\Users\\TestFolder\\flutter';
        final escaped = testPath.replaceAll("'", "''");

        expect(escaped, equals(testPath));
      });

      test('multiple quotes are all escaped', () {
        const testPath = "path'with'multiple'quotes";
        final escaped = testPath.replaceAll("'", "''");

        expect(escaped, equals("path''with''multiple''quotes"));
      });
    });

    group('install - @dev qualifier', () {
      test('uses channel-specific lookup for @dev qualifiers', () async {
        final version = FlutterVersion.parse('2.2.2@dev');

        when(() => mockReleaseClient.getChannelReleases('dev')).thenAnswer(
          (_) async => [],
        );

        await expectLater(
          archiveService.install(version, tempDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('dev channel releases metadata'),
            ),
          ),
        );

        verify(() => mockReleaseClient.getChannelReleases('dev')).called(1);
        verifyNever(() => mockReleaseClient.getReleaseByVersion(any()));
      });
    });

    group('safe install - staging directory', () {
      test('existing cache preserved on download failure', () async {
        final server =
            await _startArchiveServer(statusCode: HttpStatus.notFound);
        addTearDown(() => server.close(force: true));

        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'cache-preserved-download-fail',
          body: (svc, versionDir) async {
            versionDir.createSync(recursive: true);
            final binDir = Directory(path.join(versionDir.path, 'bin'));
            binDir.createSync(recursive: true);
            final marker = File(path.join(binDir.path, 'flutter'));
            marker.writeAsStringSync('original');

            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(isA<AppException>()),
            );

            expect(versionDir.existsSync(), isTrue);
            expect(marker.existsSync(), isTrue);
            expect(marker.readAsStringSync(), equals('original'));
          },
        );
      });

      test('existing cache preserved on checksum failure', () async {
        final server = await _startArchiveServer(
          statusCode: HttpStatus.ok,
          body: 'mismatch-content'.codeUnits,
        );
        addTearDown(() => server.close(force: true));

        final release = createTestRelease(sha256: ''.padRight(64, '0'));
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'cache-preserved-checksum-fail',
          body: (svc, versionDir) async {
            versionDir.createSync(recursive: true);
            final marker = File(path.join(versionDir.path, 'marker.txt'));
            marker.writeAsStringSync('original');

            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('corrupted or tampered'),
                ),
              ),
            );

            expect(versionDir.existsSync(), isTrue);
            expect(marker.existsSync(), isTrue);
            expect(marker.readAsStringSync(), equals('original'));
          },
        );
      });

      test('staging directory cleaned up on failure', () async {
        final server =
            await _startArchiveServer(statusCode: HttpStatus.notFound);
        addTearDown(() => server.close(force: true));

        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'staging-cleanup',
          body: (svc, versionDir) async {
            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(isA<AppException>()),
            );

            final stagingDir = Directory('${versionDir.path}.archive_staging');
            expect(stagingDir.existsSync(), isFalse);
          },
        );
      });

      test('existing cache preserved when finalize step fails', () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer(_simulateExtraction);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'finalize-failure-preserves-cache',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            versionDir.createSync(recursive: true);

            final marker = File(path.join(versionDir.path, 'existing.txt'));
            marker.writeAsStringSync('keep-me');

            final backupPath = '${versionDir.path}.archive_backup';
            File(backupPath).writeAsStringSync('block-rename');

            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('Failed to finalize archive installation'),
                ),
              ),
            );

            expect(versionDir.existsSync(), isTrue);
            expect(marker.existsSync(), isTrue);
            expect(marker.readAsStringSync(), equals('keep-me'));
            expect(
              Directory('${versionDir.path}.archive_staging').existsSync(),
              isFalse,
            );
          },
        );
      });

      test('successful finalize does not leave backup directory behind',
          () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer(_simulateExtraction);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'finalize-success-cleans-backup',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            versionDir.createSync(recursive: true);
            File(path.join(versionDir.path, 'old.txt'))
                .writeAsStringSync('old');

            await svc.install(FlutterVersion.parse('stable'), versionDir);

            expect(
              Directory('${versionDir.path}.archive_backup').existsSync(),
              isFalse,
            );
            expect(
              File(path.join(versionDir.path, 'old.txt')).existsSync(),
              isFalse,
            );
          },
        );
      });

      test('preflight backup restore failures are wrapped as AppException',
          () async {
        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        final versionDir = Directory(path.join(tempDir.path, 'stable'));
        final backupDir = Directory('${versionDir.path}.archive_backup')
          ..createSync(recursive: true);
        File(path.join(backupDir.path, 'previous-sdk.txt'))
            .writeAsStringSync('rescued');

        // Occupy the target path with a file so backup restore fails before any
        // download or extraction work begins.
        File(versionDir.path).writeAsStringSync('occupied');

        await expectLater(
          archiveService.install(FlutterVersion.parse('stable'), versionDir),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              contains('Failed to restore archive backup directory'),
            ),
          ),
        );

        expect(backupDir.existsSync(), isTrue);
      });

      test('interrupted install recovers backup when versionDir is missing',
          () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer(_simulateExtraction);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'interrupted-install-recovers-backup',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            // Simulate interrupted state: backup exists, versionDir does not
            final backupDir = Directory('${versionDir.path}.archive_backup');
            backupDir.createSync(recursive: true);
            final marker = File(path.join(backupDir.path, 'previous-sdk.txt'));
            marker.writeAsStringSync('rescued');

            expect(versionDir.existsSync(), isFalse);

            // install() should recover backup to versionDir before proceeding
            await svc.install(FlutterVersion.parse('stable'), versionDir);

            // After successful install the backup must be gone and
            // versionDir must contain the new archive content
            expect(backupDir.existsSync(), isFalse);
            expect(versionDir.existsSync(), isTrue);
          },
        );
      });

      test('serializes concurrent installs for the same version', () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);
        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();
        final firstExtractionStarted = Completer<void>();
        final allowFirstExtractionToFinish = Completer<void>();
        var extractionRuns = 0;

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer((invocation) async {
          extractionRuns++;

          if (extractionRuns == 1) {
            firstExtractionStarted.complete();
            await allowFirstExtractionToFinish.future;
          }

          return _simulateExtraction(invocation);
        });

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'concurrent-install-lock',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            final firstInstall = svc.install(
              FlutterVersion.parse('stable'),
              versionDir,
            );
            await firstExtractionStarted.future;

            final secondInstall = svc.install(
              FlutterVersion.parse('stable'),
              versionDir,
            );

            await Future<void>.delayed(const Duration(milliseconds: 120));
            expect(
              extractionRuns,
              equals(1),
              reason:
                  'Second install should wait for the first install lock to release.',
            );

            allowFirstExtractionToFinish.complete();
            await Future.wait([firstInstall, secondInstall]);

            final execName = Platform.isWindows ? 'flutter.bat' : 'flutter';
            expect(extractionRuns, equals(2));
            expect(
              File(path.join(versionDir.path, 'bin', execName)).existsSync(),
              isTrue,
            );
            expect(
              Directory('${versionDir.path}.archive_staging').existsSync(),
              isFalse,
            );
            expect(
              Directory('${versionDir.path}.archive_backup').existsSync(),
              isFalse,
            );
          },
        );
      });
    });

    group('structure flattening and validation', () {
      test('flattens flutter/ subdirectory into target root', () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer(
          (invocation) => _simulateExtraction(
            invocation,
            onPrepared: (_, sdkRootDir, __) {
              File(path.join(sdkRootDir.path, 'README'))
                  .writeAsStringSync('readme');
            },
          ),
        );

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'flatten-test',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            await svc.install(FlutterVersion.parse('stable'), versionDir);

            final execName = Platform.isWindows ? 'flutter.bat' : 'flutter';
            expect(
              File(path.join(versionDir.path, 'bin', execName)).existsSync(),
              isTrue,
            );
            expect(
              File(path.join(versionDir.path, 'README')).existsSync(),
              isTrue,
            );
            expect(
              Directory(path.join(versionDir.path, 'flutter')).existsSync(),
              isFalse,
            );
          },
        );
      });

      test('skips __MACOSX during flatten', () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer(
          (invocation) => _simulateExtraction(
            invocation,
            onPrepared: (_, sdkRootDir, __) {
              Directory(path.join(sdkRootDir.path, '__MACOSX')).createSync();
            },
          ),
        );

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'macosx-skip-test',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            await svc.install(FlutterVersion.parse('stable'), versionDir);

            expect(
              Directory(path.join(versionDir.path, '__MACOSX')).existsSync(),
              isFalse,
            );
          },
        );
      });

      test('no-op flatten when no flutter/ dir exists', () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer(
          (invocation) =>
              _simulateExtraction(invocation, createFlutterSubdir: false),
        );

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'no-flatten-test',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            await svc.install(FlutterVersion.parse('stable'), versionDir);

            final execName = Platform.isWindows ? 'flutter.bat' : 'flutter';
            expect(
              File(path.join(versionDir.path, 'bin', execName)).existsSync(),
              isTrue,
            );
          },
        );
      });

      test('throws when flutter binary missing after extraction', () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer((_) async => ProcessResult(0, 0, '', ''));

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'missing-binary-test',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('flutter executable was not found'),
                ),
              ),
            );
          },
        );
      });

      test(
        'throws when extracted symlink points outside sdk directory',
        () async {
          final archiveBytes = 'dummy-zip-data'.codeUnits;
          final hash = sha256.convert(archiveBytes).toString();
          final release = createTestRelease(sha256: hash);
          final server = await _startArchiveServer(body: archiveBytes);
          addTearDown(() => server.close(force: true));

          final mockProcessService = MockProcessService();

          when(() => mockReleaseClient.getLatestChannelRelease('stable'))
              .thenAnswer((_) async => release);

          when(
            () => mockProcessService.run(
              any(),
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
              environment: any(named: 'environment'),
              throwOnError: any(named: 'throwOnError'),
              echoOutput: any(named: 'echoOutput'),
            ),
          ).thenAnswer(
            (invocation) => _simulateExtraction(
              invocation,
              onPrepared: (targetDir, _, binDir) {
                final outsideDir = Directory(
                  path.join(targetDir.parent.path, 'outside_target'),
                )..createSync(recursive: true);
                final outsideFile =
                    File(path.join(outsideDir.path, 'outside.txt'))
                      ..writeAsStringSync('outside');
                final escapedLink = Link(path.join(binDir.path, 'escape_link'));
                escapedLink.createSync(outsideFile.path);
              },
            ),
          );

          await withArchiveTestZone(
            port: server.port,
            debugLabel: 'symlink-safety-test',
            extraGenerators: {ProcessService: (_) => mockProcessService},
            body: (svc, versionDir) async {
              await expectLater(
                svc.install(FlutterVersion.parse('stable'), versionDir),
                throwsA(
                  isA<AppException>().having(
                    (e) => e.message,
                    'message',
                    contains('symlink that points outside'),
                  ),
                ),
              );
            },
          );
        },
        skip: Platform.isWindows
            ? 'Windows symlink creation requires elevated privileges.'
            : null,
      );

      test(
        'throws when extracted symlink resolves outside sdk directory via multi-hop chain',
        () async {
          final archiveBytes = 'dummy-zip-data'.codeUnits;
          final hash = sha256.convert(archiveBytes).toString();
          final release = createTestRelease(sha256: hash);
          final server = await _startArchiveServer(body: archiveBytes);
          addTearDown(() => server.close(force: true));

          final mockProcessService = MockProcessService();

          when(() => mockReleaseClient.getLatestChannelRelease('stable'))
              .thenAnswer((_) async => release);

          when(
            () => mockProcessService.run(
              any(),
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
              environment: any(named: 'environment'),
              throwOnError: any(named: 'throwOnError'),
              echoOutput: any(named: 'echoOutput'),
            ),
          ).thenAnswer(
            (invocation) => _simulateExtraction(
              invocation,
              onPrepared: (targetDir, _, binDir) {
                final outsideDir = Directory(
                  path.join(targetDir.parent.path, 'outside_multi_hop'),
                )..createSync(recursive: true);
                final outsideFile =
                    File(path.join(outsideDir.path, 'outside.txt'))
                      ..writeAsStringSync('outside');
                final innerLinksDir =
                    Directory(path.join(binDir.path, 'inner_links'))
                      ..createSync(recursive: true);

                final secondHop = Link(
                  path.join(innerLinksDir.path, 'second_hop'),
                );
                secondHop.createSync(outsideFile.path);

                final firstHop = Link(path.join(binDir.path, 'multi_hop'));
                firstHop.createSync(path.join('inner_links', 'second_hop'));
              },
            ),
          );

          await withArchiveTestZone(
            port: server.port,
            debugLabel: 'symlink-multi-hop-safety-test',
            extraGenerators: {ProcessService: (_) => mockProcessService},
            body: (svc, versionDir) async {
              await expectLater(
                svc.install(FlutterVersion.parse('stable'), versionDir),
                throwsA(
                  isA<AppException>().having(
                    (e) => e.message,
                    'message',
                    contains('symlink that points outside'),
                  ),
                ),
              );
            },
          );
        },
        skip: Platform.isWindows
            ? 'Windows symlink creation requires elevated privileges.'
            : null,
      );
    });

    group('archiveUrl construction', () {
      test('is built from FlutterReleaseClient.storageUrl prefix', () {
        final release = createTestRelease(
          archive: 'stable/linux/flutter_linux_3.16.0-stable.tar.xz',
        );

        final expectedPrefix = FlutterReleaseClient.storageUrl;
        expect(
          release.archiveUrl,
          equals(
            '$expectedPrefix/flutter_infra_release/releases/'
            'stable/linux/flutter_linux_3.16.0-stable.tar.xz',
          ),
        );
      });
    });

    group('platform-specific extraction', () {
      test('tar.xz archive calls tar with correct args', () async {
        final archiveBytes = 'dummy-tar-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(
          sha256: hash,
          archive: 'stable/linux/flutter_linux_3.16.0-stable.tar.xz',
        );

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer((_) async => ProcessResult(0, 0, '', ''));

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'tar-args-test',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            try {
              await svc.install(FlutterVersion.parse('stable'), versionDir);
            } catch (_) {}

            final captured = verify(
              () => mockProcessService.run(
                'tar',
                args: captureAny(named: 'args'),
                workingDirectory: any(named: 'workingDirectory'),
                environment: any(named: 'environment'),
                throwOnError: any(named: 'throwOnError'),
                echoOutput: any(named: 'echoOutput'),
              ),
            ).captured;

            expect(captured, isNotEmpty);
            final args = captured.first as List<String>;
            expect(args[0], equals('-xJf'));
            expect(args[2], equals('-C'));
          },
        );
      });

      test('zip archive on non-Windows calls unzip with correct args',
          () async {
        final archiveBytes = 'dummy-zip-data'.codeUnits;
        final hash = sha256.convert(archiveBytes).toString();
        final release = createTestRelease(sha256: hash);

        final server = await _startArchiveServer(body: archiveBytes);
        addTearDown(() => server.close(force: true));

        final mockProcessService = MockProcessService();

        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        when(
          () => mockProcessService.run(
            any(),
            args: any(named: 'args'),
            workingDirectory: any(named: 'workingDirectory'),
            environment: any(named: 'environment'),
            throwOnError: any(named: 'throwOnError'),
            echoOutput: any(named: 'echoOutput'),
          ),
        ).thenAnswer((_) async => ProcessResult(0, 0, '', ''));

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'unzip-args-test',
          extraGenerators: {ProcessService: (_) => mockProcessService},
          body: (svc, versionDir) async {
            try {
              await svc.install(FlutterVersion.parse('stable'), versionDir);
            } catch (_) {}

            if (!Platform.isWindows) {
              final captured = verify(
                () => mockProcessService.run(
                  'unzip',
                  args: captureAny(named: 'args'),
                  workingDirectory: any(named: 'workingDirectory'),
                  environment: any(named: 'environment'),
                  throwOnError: any(named: 'throwOnError'),
                  echoOutput: any(named: 'echoOutput'),
                ),
              ).captured;

              expect(captured, isNotEmpty);
              final args = captured.first as List<String>;
              expect(args[0], equals('-q'));
              expect(args[1], equals('-o'));
              expect(args[3], equals('-d'));
            }
          },
        );
      });
    });

    group('network error handling', () {
      test('wraps SocketException with network error message', () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final port = server.port;
        await server.close(force: true);

        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        await withArchiveTestZone(
          port: port,
          debugLabel: 'socket-error',
          body: (svc, versionDir) async {
            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  anyOf(
                    contains('Network error'),
                    contains('Failed to download'),
                  ),
                ),
              ),
            );
          },
        );
      });

      test('wraps HandshakeException with TLS guidance message', () async {
        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        final overrides = _ThrowingHttpOverrides(
          const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
        );

        await HttpOverrides.runZoned(
          () async {
            final ctx = TestFactory.context(
              debugLabel: 'tls-handshake-error',
              generators: {
                FlutterReleaseClient: (_) => mockReleaseClient,
              },
            );

            final svc = ArchiveService(ctx);
            tempDir = Directory(ctx.versionsCachePath);
            final versionDir = Directory(path.join(tempDir.path, 'stable'));

            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  allOf(
                    contains('TLS certificate verification failed'),
                    contains('self-signed'),
                  ),
                ),
              ),
            );
          },
          createHttpClient: overrides.createHttpClient,
        );
      });

      test('wraps timeout SocketException with network error message',
          () async {
        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        final overrides = _ThrowingHttpOverrides(
          const SocketException('Connection timed out'),
        );

        await HttpOverrides.runZoned(
          () async {
            final ctx = TestFactory.context(
              debugLabel: 'timeout-socket-error',
              generators: {
                FlutterReleaseClient: (_) => mockReleaseClient,
              },
            );

            final svc = ArchiveService(ctx);
            tempDir = Directory(ctx.versionsCachePath);
            final versionDir = Directory(path.join(tempDir.path, 'stable'));

            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('Network error'),
                ),
              ),
            );
          },
          createHttpClient: overrides.createHttpClient,
        );
      });

      test('wraps delayed header response as timeout with retry guidance',
          () async {
        final server = await _startDelayedHeaderServer(
          headerDelay: const Duration(milliseconds: 300),
        );
        addTearDown(() => server.close(force: true));

        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'header-timeout',
          responseTimeout: const Duration(milliseconds: 100),
          readTimeout: const Duration(milliseconds: 400),
          body: (svc, versionDir) async {
            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  allOf(
                    contains(
                        'Timed out while waiting for response from server'),
                    contains('Please retry'),
                  ),
                ),
              ),
            );

            expectTrackedArchiveTempDirsDeleted();
            expect(
              Directory('${versionDir.path}.archive_staging').existsSync(),
              isFalse,
            );
          },
        );
      });

      test('wraps stalled body stream as timeout with retry guidance',
          () async {
        final server = await _startStalledBodyServer(
          stallDuration: const Duration(milliseconds: 300),
        );
        addTearDown(() => server.close(force: true));

        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        await withArchiveTestZone(
          port: server.port,
          debugLabel: 'read-timeout',
          responseTimeout: const Duration(milliseconds: 200),
          readTimeout: const Duration(milliseconds: 100),
          body: (svc, versionDir) async {
            await expectLater(
              svc.install(FlutterVersion.parse('stable'), versionDir),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  allOf(
                    contains('Timed out while waiting for download data'),
                    contains('Please retry'),
                  ),
                ),
              ),
            );

            expectTrackedArchiveTempDirsDeleted();
            expect(
              Directory('${versionDir.path}.archive_staging').existsSync(),
              isFalse,
            );
          },
        );
      });
    });
  });
}
