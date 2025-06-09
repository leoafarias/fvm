import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../models/flutter_version_model.dart';
import '../utils/exceptions.dart';
import '../version.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'releases_service/releases_client.dart';

/// Service for downloading and extracting Flutter SDK archives
class DownloadService extends ContextualService {
  const DownloadService(super.context);

  /// Downloads the archive file from the given URL
  Future<File> _downloadArchive(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(minutes: 2);

    final tempDir = await Directory.systemTemp.createTemp('fvm_flutter_sdk_');
    final tempFile = File(path.join(tempDir.path, 'flutter_sdk.archive'));

    try {
      final request = await client.getUrl(Uri.parse(url))
        ..headers.set('User-Agent', 'FVM/$packageVersion');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw AppException('Failed to download: HTTP ${response.statusCode}');
      }

      final sink = tempFile.openWrite();
      final progress = logger.progress('Downloading Flutter SDK');
      int downloaded = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        downloaded += chunk.length;

        final mb = (downloaded / 1024 / 1024).toStringAsFixed(1);
        if (response.contentLength > 0) {
          final percent =
              (downloaded / response.contentLength * 100).toStringAsFixed(0);
          final totalMB =
              (response.contentLength / 1024 / 1024).toStringAsFixed(1);
          progress.update('$percent% - ${mb}MB/${totalMB}MB');
        } else {
          progress.update('${mb}MB downloaded');
        }
      }

      await sink.close();
      final finalMB = (downloaded / 1024 / 1024).toStringAsFixed(1);
      progress.complete('Download complete (${finalMB}MB)');

      return tempFile;
    } catch (e) {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Extracts a Flutter SDK archive to the specified directory
  Future<void> _extractArchive(File archiveFile, Directory targetDir) async {
    final archiveBytes = await archiveFile.readAsBytes();

    // Decode based on platform
    final archive = Platform.isLinux
        ? TarDecoder().decodeBytes(XZDecoder().decodeBytes(archiveBytes))
        : ZipDecoder().decodeBytes(archiveBytes);

    targetDir.createSync(recursive: true);

    for (final file in archive) {
      if (file.name.isEmpty || file.name.contains('..')) continue;

      // Remove flutter/ prefix
      final parts = file.name.split('/');
      if (parts.isEmpty || (parts.first == 'flutter' && parts.length == 1)) {
        continue;
      }

      final relativePath =
          parts.first == 'flutter' ? parts.skip(1).join('/') : file.name;
      if (relativePath.isEmpty) continue;

      final filePath = path.join(targetDir.path, relativePath);

      if (file.isFile) {
        final outputFile = File(filePath);
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(file.content);

        // Set executable permissions for binaries
        if (!Platform.isWindows &&
            (relativePath.startsWith('bin/') ||
                relativePath.contains('/bin/')) &&
            !relativePath.endsWith('.bat')) {
          try {
            Process.runSync('chmod', ['+x', filePath]);
          } catch (_) {}
        }
      } else {
        Directory(filePath).createSync(recursive: true);
      }
    }
  }

  /// Verifies that the extraction was successful
  void _verifyExtraction(Directory versionDir) {
    final flutterBin = File(path.join(versionDir.path, 'bin', 'flutter'));
    final versionFile = File(path.join(versionDir.path, 'version'));

    if (!flutterBin.existsSync() || !versionFile.existsSync()) {
      throw AppException(
        'Flutter SDK extraction failed - missing essential files',
      );
    }
  }

  /// Checks if a version can be downloaded (is an official release)
  Future<bool> canDownload(FlutterVersion version) async {
    // Only official releases can be downloaded
    if (version.isCustom || version.fromFork) {
      return false;
    }

    try {
      final releaseClient = get<FlutterReleaseClient>();
      final release = await releaseClient.getReleaseByVersion(version.version);

      return release != null;
    } catch (e) {
      logger.debug('Failed to check if version can be downloaded: $e');

      return false;
    }
  }

  /// Downloads and extracts a Flutter SDK archive for the given version
  Future<void> downloadAndExtract(FlutterVersion version) async {
    final release =
        await get<FlutterReleaseClient>().getReleaseByVersion(version.version);
    if (release == null) {
      throw AppException(
        'Version ${version.version} is not available for download',
      );
    }

    final versionDir = get<CacheService>().getVersionCacheDir(version);
    versionDir.parent.createSync(recursive: true);

    File? tempFile;
    try {
      tempFile = await _downloadArchive(release.archiveUrl);
      await _extractArchive(tempFile, versionDir);
      _verifyExtraction(versionDir);
      logger.info('Flutter SDK downloaded and extracted successfully!');
    } finally {
      if (tempFile?.parent.existsSync() == true) {
        tempFile!.parent.deleteSync(recursive: true);
      }
    }
  }
}
