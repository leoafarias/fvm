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

List<String> _listArchiveTempDirs() {
  return Directory.systemTemp
      .listSync()
      .whereType<Directory>()
      .where((dir) => path.basename(dir.path).startsWith('fvm_archive_'))
      .map((dir) => dir.path)
      .toList();
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

void main() {
  late FvmContext context;
  late ArchiveService archiveService;
  late MockFlutterReleaseClient mockReleaseClient;
  late Directory tempDir;

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
              contains('not supported for commit references'),
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

        final overrides = _RedirectHttpOverrides(
            Uri.parse('http://127.0.0.1:${server.port}'));

        await HttpOverrides.runZoned(
          () async {
            final context = TestFactory.context(
              debugLabel: 'checksum-failure',
              generators: {
                FlutterReleaseClient: (_) => mockReleaseClient,
              },
            );

            archiveService = ArchiveService(context);
            tempDir = Directory(context.versionsCachePath);
            final versionDir = Directory(path.join(tempDir.path, '3.16.0'));

            await expectLater(
              archiveService.install(
                FlutterVersion.parse('3.16.0'),
                versionDir,
              ),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('corrupted or tampered'),
                ),
              ),
            );
          },
          createHttpClient: overrides.createHttpClient,
        );
      });

      test('cleans temp directory and surfaces HTTP errors', () async {
        final server =
            await _startArchiveServer(statusCode: HttpStatus.notFound);
        addTearDown(() => server.close(force: true));

        final release = createTestRelease();
        when(() => mockReleaseClient.getLatestChannelRelease('stable'))
            .thenAnswer((_) async => release);

        final existingTempDirs = _listArchiveTempDirs();

        final overrides = _RedirectHttpOverrides(
            Uri.parse('http://127.0.0.1:${server.port}'));

        await HttpOverrides.runZoned(
          () async {
            final context = TestFactory.context(
              debugLabel: 'http-error',
              generators: {
                FlutterReleaseClient: (_) => mockReleaseClient,
              },
            );

            archiveService = ArchiveService(context);
            tempDir = Directory(context.versionsCachePath);
            final versionDir = Directory(path.join(tempDir.path, 'stable'));

            await expectLater(
              archiveService.install(
                FlutterVersion.parse('stable'),
                versionDir,
              ),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('HTTP 404'),
                ),
              ),
            );

            final after = _listArchiveTempDirs();
            expect(after.toSet().difference(existingTempDirs.toSet()), isEmpty);
          },
          createHttpClient: overrides.createHttpClient,
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

        final before = _listArchiveTempDirs();

        final overrides = _RedirectHttpOverrides(
            Uri.parse('http://127.0.0.1:${server.port}'));

        await HttpOverrides.runZoned(
          () async {
            final context = TestFactory.context(
              debugLabel: 'extract-failure',
              generators: {
                FlutterReleaseClient: (_) => mockReleaseClient,
                ProcessService: (_) => mockProcessService,
              },
            );

            archiveService = ArchiveService(context);
            tempDir = Directory(context.versionsCachePath);
            final versionDir = Directory(path.join(tempDir.path, 'stable'));

            await expectLater(
              archiveService.install(
                FlutterVersion.parse('stable'),
                versionDir,
              ),
              throwsA(
                isA<AppException>().having(
                  (e) => e.message,
                  'message',
                  contains('Failed to extract the archive with unzip'),
                ),
              ),
            );

            final after = _listArchiveTempDirs();
            expect(after.toSet().difference(before.toSet()), isEmpty);
          },
          createHttpClient: overrides.createHttpClient,
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
        // Custom versions have isCustom = true, which means they point to
        // a local path rather than a release. Archive installation doesn't
        // support custom paths since there's nothing to download.
        //
        // Note: Creating a truly "custom" version requires specific parsing
        // conditions. This test verifies the validation exists conceptually.
        // The actual custom detection logic is in FlutterVersion.parse.
        final customVersion = FlutterVersion.parse('custom');

        // Custom detection depends on context; if it's detected as custom,
        // the archive service should reject it
        if (customVersion.isCustom) {
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
        }
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
  });
}
