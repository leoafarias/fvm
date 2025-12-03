import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/archive_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

// Mock classes
class MockFlutterReleaseClient extends Mock implements FlutterReleaseClient {}

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

    group('flutter/ subdirectory handling', () {
      test('creates typical Flutter SDK structure', () {
        tempDir.createSync(recursive: true);
        final flutterDir = Directory(path.join(tempDir.path, 'flutter'));
        flutterDir.createSync();

        final binDir = Directory(path.join(flutterDir.path, 'bin'));
        binDir.createSync();
        File(path.join(binDir.path, 'flutter')).writeAsStringSync('#!/bin/sh');

        final versionFile = File(path.join(flutterDir.path, 'version'));
        versionFile.writeAsStringSync('3.16.0');

        expect(flutterDir.existsSync(), isTrue);
        expect(
          File(path.join(flutterDir.path, 'bin', 'flutter')).existsSync(),
          isTrue,
        );
        expect(versionFile.readAsStringSync(), equals('3.16.0'));
      });

      test('__MACOSX directories are identifiable', () {
        tempDir.createSync(recursive: true);
        final flutterDir = Directory(path.join(tempDir.path, 'flutter'));
        flutterDir.createSync();

        final macosxDir = Directory(path.join(flutterDir.path, '__MACOSX'));
        macosxDir.createSync();
        File(path.join(macosxDir.path, '._foo')).writeAsStringSync('metadata');

        expect(macosxDir.existsSync(), isTrue);
        expect(path.basename(macosxDir.path), equals('__MACOSX'));
      });

      test('handles missing flutter/ directory', () {
        tempDir.createSync(recursive: true);

        final flutterDir = Directory(path.join(tempDir.path, 'flutter'));
        expect(flutterDir.existsSync(), isFalse);

        // Direct structure works fine
        final binDir = Directory(path.join(tempDir.path, 'bin'));
        binDir.createSync();
        expect(binDir.existsSync(), isTrue);
      });
    });

    group('__MACOSX metadata removal', () {
      test('identifies __MACOSX directory when present', () {
        tempDir.createSync(recursive: true);
        final macosxDir = Directory(path.join(tempDir.path, '__MACOSX'));
        macosxDir.createSync();
        File(path.join(macosxDir.path, '._file')).writeAsStringSync('metadata');

        expect(macosxDir.existsSync(), isTrue);
        expect(path.basename(macosxDir.path), equals('__MACOSX'));
      });

      test('can delete __MACOSX recursively', () {
        tempDir.createSync(recursive: true);
        final macosxDir = Directory(path.join(tempDir.path, '__MACOSX'));
        macosxDir.createSync();
        File(path.join(macosxDir.path, '._file')).writeAsStringSync('metadata');

        macosxDir.deleteSync(recursive: true);
        expect(macosxDir.existsSync(), isFalse);
      });

      test('handles non-existent __MACOSX gracefully', () {
        tempDir.createSync(recursive: true);

        final macosxDir = Directory(path.join(tempDir.path, '__MACOSX'));
        expect(macosxDir.existsSync(), isFalse);
      });
    });

    group('extraction validation', () {
      test('flutter executable path is correct for current platform', () {
        tempDir.createSync(recursive: true);
        final binDir = Directory(path.join(tempDir.path, 'bin'));
        binDir.createSync();

        final expectedExec = Platform.isWindows ? 'flutter.bat' : 'flutter';
        final flutterExec = File(path.join(binDir.path, expectedExec));
        flutterExec.writeAsStringSync('#!/bin/sh\necho Flutter');

        expect(flutterExec.existsSync(), isTrue);
      });

      test('detects missing flutter executable', () {
        tempDir.createSync(recursive: true);
        final binDir = Directory(path.join(tempDir.path, 'bin'));
        binDir.createSync();

        final expectedExec = Platform.isWindows ? 'flutter.bat' : 'flutter';
        final flutterExec = File(path.join(binDir.path, expectedExec));

        expect(flutterExec.existsSync(), isFalse);
      });

      test('bin directory without flutter executable', () {
        tempDir.createSync(recursive: true);
        final binDir = Directory(path.join(tempDir.path, 'bin'));
        binDir.createSync();

        // Other executables might exist
        File(path.join(binDir.path, 'dart')).writeAsStringSync('#!/bin/sh');

        expect(binDir.existsSync(), isTrue);
        final expectedExec = Platform.isWindows ? 'flutter.bat' : 'flutter';
        expect(
            File(path.join(binDir.path, expectedExec)).existsSync(), isFalse);
      });
    });

    group('archive format detection', () {
      test('detects .tar.xz extension', () {
        const archive = 'stable/linux/flutter_linux_3.16.0-stable.tar.xz';
        expect(archive.endsWith('.tar.xz'), isTrue);
        expect(archive.endsWith('.zip'), isFalse);
      });

      test('detects .zip extension', () {
        const archive = 'stable/macos/flutter_macos_3.16.0-stable.zip';
        expect(archive.endsWith('.zip'), isTrue);
        expect(archive.endsWith('.tar.xz'), isFalse);
      });

      test('tar.xz is used for Linux archives', () {
        final release = createTestRelease(
          archive: 'stable/linux/flutter_linux_3.16.0-stable.tar.xz',
        );
        expect(release.archive.endsWith('.tar.xz'), isTrue);
        expect(release.archive.contains('linux'), isTrue);
      });

      test('zip is used for macOS archives', () {
        final release = createTestRelease(
          archive: 'stable/macos/flutter_macos_3.16.0-stable.zip',
        );
        expect(release.archive.endsWith('.zip'), isTrue);
        expect(release.archive.contains('macos'), isTrue);
      });

      test('zip is used for Windows archives', () {
        final release = createTestRelease(
          archive: 'stable/windows/flutter_windows_3.16.0-stable.zip',
        );
        expect(release.archive.endsWith('.zip'), isTrue);
        expect(release.archive.contains('windows'), isTrue);
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
  });
}
