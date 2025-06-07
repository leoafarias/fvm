import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../models/flutter_version_model.dart';
import '../utils/exceptions.dart';
import 'base_service.dart';
import 'cache_service.dart';
import 'releases_service/releases_client.dart';

/// Service for downloading and extracting Flutter SDK archives
class DownloadService extends ContextualService {
  const DownloadService(super.context);

  /// Downloads and extracts a Flutter SDK archive for the given version
  Future<void> downloadAndExtract(FlutterVersion version) async {
    final releaseClient = get<FlutterReleaseClient>();
    final cacheService = get<CacheService>();

    // Get release information from the releases API
    final release = await releaseClient.getReleaseByVersion(version.version);
    if (release == null) {
      throw AppException(
        'Version ${version.version} is not available for download. '
        'Only official Flutter releases can be downloaded as archives.',
      );
    }

    // Get the target directory for extraction
    final versionDir = cacheService.getVersionCacheDir(version);

    // Create parent directories if needed
    if (!versionDir.parent.existsSync()) {
      versionDir.parent.createSync(recursive: true);
    }

    // Download the archive
    logger.info('Downloading Flutter SDK archive...');
    final archiveBytes = await _downloadArchive(release.archiveUrl);

    // Extract the archive
    logger.info('Extracting Flutter SDK archive...');
    await _extractArchive(archiveBytes, versionDir);

    // Verify the extraction was successful
    await _verifyExtraction(versionDir);

    logger.info('Flutter SDK downloaded and extracted successfully!');
  }

  /// Downloads the archive file from the given URL
  Future<Uint8List> _downloadArchive(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw AppException(
          'Failed to download archive: HTTP ${response.statusCode}',
        );
      }

      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }

      client.close();

      return Uint8List.fromList(bytes);
    } catch (e) {
      throw AppException(
        'Failed to download Flutter SDK archive: $e',
      );
    }
  }

  /// Extracts a tar.xz archive to the specified directory
  Future<void> _extractArchive(Uint8List archiveBytes, Directory targetDir) async {
    try {
      // Decompress XZ and extract TAR
      final xzDecoder = XZDecoder();
      final tarBytes = xzDecoder.decodeBytes(archiveBytes);
      final tarArchive = TarDecoder().decodeBytes(tarBytes);

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      // Extract files, removing flutter/ prefix from paths
      for (final file in tarArchive) {
        if (file.name.isEmpty || file.name.contains('..')) continue;

        // Remove flutter/ prefix: flutter/bin/flutter -> bin/flutter
        final parts = file.name.split('/');
        if (parts.isEmpty || (parts.first == 'flutter' && parts.length == 1)) continue;

        final relativePath = parts.first == 'flutter' ? parts.skip(1).join('/') : file.name;
        if (relativePath.isEmpty) continue;

        final filePath = path.join(targetDir.path, relativePath);

        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.parent.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);

          // Set executable permissions for binaries
          if (relativePath.contains('/bin/') && !relativePath.endsWith('.bat')) {
            _setExecutablePermissions(outputFile);
          }
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }
    } catch (e) {
      throw AppException('Failed to extract Flutter SDK archive: $e');
    }
  }

  /// Sets executable permissions on a file (Unix-like systems only)
  void _setExecutablePermissions(File file) {
    if (!Platform.isWindows) {
      try {
        Process.runSync('chmod', ['+x', file.path]);
      } catch (e) {
        logger.warn('Failed to set executable permissions for ${file.path}: $e');
      }
    }
  }

  /// Verifies that the extraction was successful
  Future<void> _verifyExtraction(Directory versionDir) async {
    // Check for essential Flutter files
    final flutterBin = File(path.join(versionDir.path, 'bin', 'flutter'));
    final versionFile = File(path.join(versionDir.path, 'version'));

    if (!flutterBin.existsSync()) {
      throw AppException(
        'Flutter binary not found after extraction. The archive may be corrupted.',
      );
    }

    if (!versionFile.existsSync()) {
      throw AppException(
        'Version file not found after extraction. The archive may be corrupted.',
      );
    }

    logger.debug('Extraction verification successful');
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
}
