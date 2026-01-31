import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/download_service.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';



void main() {
  group('DownloadService', () {
    late DownloadService downloadService;
    late Directory tempDir;

    setUp(() {
      tempDir = createTempDir('download_service_test');
      // Use real services - no mocking
      final context = TestFactory.context();
      downloadService = DownloadService(context);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('canDownload', () {
      test('returns true for real official release versions', () async {
        final version = FlutterVersion.parse('3.24.0');
        final result = await downloadService.canDownload(version);
        expect(result, isTrue);
      });

      test('returns false for custom versions', () async {
        final version = FlutterVersion.custom('custom_test');
        final result = await downloadService.canDownload(version);
        expect(result, isFalse);
      });

      test('returns false for fork versions', () async {
        final version = FlutterVersion.parse('fork/stable');
        final result = await downloadService.canDownload(version);
        expect(result, isFalse);
      });

      test('returns false for non-existent versions', () async {
        final version = FlutterVersion.parse('999.999.999');
        final result = await downloadService.canDownload(version);
        expect(result, isFalse);
      });
    });

    group('downloadAndExtract', () {
      test('throws AppException when version is not available for download', () async {
        final version = FlutterVersion.parse('999.999.999');

        expect(
          () => downloadService.downloadAndExtract(version),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Version 999.999.999 is not available for download'),
            ),
          ),
        );
      });
    });

  });

  group('DownloadService Integration Tests', () {
    test('validates real Flutter release data and hash if available', () async {
      final context = TestFactory.context();
      final downloadService = DownloadService(context);
      final releaseClient = context.get<FlutterReleaseClient>();

      // Test with a known stable version
      final version = FlutterVersion.parse('3.24.0');
      final canDownload = await downloadService.canDownload(version);
      expect(canDownload, isTrue);

      // Get the actual release data
      final release = await releaseClient.getReleaseByVersion('3.24.0');
      expect(release, isNotNull);
      expect(release!.archiveUrl, isNotEmpty);

      // Validate the archive URL format
      expect(release.archiveUrl, contains('flutter_'));
      if (Platform.isLinux) {
        expect(release.archiveUrl, contains('.tar.xz'));
      } else if (Platform.isMacOS || Platform.isWindows) {
        expect(release.archiveUrl, contains('.zip'));
      }

      // If SHA256 is available, validate it's a proper hash
      if (release.sha256.isNotEmpty) {
        expect(release.sha256.length, equals(64)); // SHA256 is 64 hex chars
        expect(RegExp(r'^[a-f0-9]+$').hasMatch(release.sha256), isTrue);
      }
    });

    test('correctly identifies non-downloadable versions', () async {
      final context = TestFactory.context();
      final downloadService = DownloadService(context);

      // Test with custom version
      final customVersion = FlutterVersion.custom('custom_test');
      final canDownloadCustom = await downloadService.canDownload(customVersion);
      expect(canDownloadCustom, isFalse);

      // Test with fork version
      final forkVersion = FlutterVersion.parse('fork/stable');
      final canDownloadFork = await downloadService.canDownload(forkVersion);
      expect(canDownloadFork, isFalse);
    });

    test('validates actual download workflow with real version', () async {
      final context = TestFactory.context();
      final downloadService = DownloadService(context);
      final cacheService = context.get<CacheService>();

      // Use a known stable version that's available across platforms
      final version = FlutterVersion.parse('3.0.0');
      final canDownload = await downloadService.canDownload(version);
      expect(canDownload, isTrue, 
        reason: 'Version 3.0.0 must be downloadable for this test to run');

      if (!canDownload) {
        // Skip test if version not available for download
        return;
      }

      // Get version directory
      final versionDir = cacheService.getVersionCacheDir(version);

      // Clean up any existing installation
      if (versionDir.existsSync()) {
        versionDir.deleteSync(recursive: true);
      }

      try {
        // Perform actual download and extraction
        await downloadService.downloadAndExtract(version);

        // Verify essential files exist
        final flutterBin = File('${versionDir.path}/bin/flutter');
        final versionFile = File('${versionDir.path}/version');

        expect(versionDir.existsSync(), isTrue);
        expect(flutterBin.existsSync(), isTrue);
        expect(versionFile.existsSync(), isTrue);

        // Verify version file content
        final versionContent = versionFile.readAsStringSync().trim();
        expect(versionContent, contains('3.0.0'));

      } finally {
        // Clean up
        if (versionDir.existsSync()) {
          versionDir.deleteSync(recursive: true);
        }
      }
    }, timeout: Timeout(Duration(minutes: 5))); // Allow time for download
  });
}
