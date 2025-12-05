import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../models/flutter_version_model.dart';
import '../utils/constants.dart';
import '../utils/exceptions.dart';
import 'base_service.dart';
import 'process_service.dart';
import 'releases_service/models/version_model.dart';
import 'releases_service/releases_client.dart';

class ArchiveService extends ContextualService {
  static const _supportedArchiveChannels = {'stable', 'beta', 'dev'};

  const ArchiveService(super.context);

  void _validateSupportedVersion(FlutterVersion version) {
    if (version.fromFork) {
      throw const AppException(
        'Archive installation is not supported for forked Flutter SDKs. '
        'Please remove the --archive flag or install the fork via git.',
      );
    }

    if (version.isUnknownRef) {
      throw const AppException(
        'Archive installation is not supported for commit references. '
        'Remove the --archive flag to install from git.',
      );
    }

    if (version.isCustom) {
      throw const AppException(
        'Archive installation is not supported for custom Flutter SDKs.',
      );
    }
  }

  Future<FlutterSdkRelease> _resolveRelease(FlutterVersion version) async {
    final releaseClient = get<FlutterReleaseClient>();

    if (version.isChannel) {
      if (!_supportedArchiveChannels.contains(version.name)) {
        throw AppException(
          'Archive installation is available only for the stable, beta, or dev '
          'channels. Remove the --archive flag or choose a supported channel.',
        );
      }

      return releaseClient.getLatestChannelRelease(version.name);
    }

    if (version.isRelease) {
      final release = await releaseClient.getReleaseByVersion(version.version);
      if (release == null) {
        throw AppException(
          'Release ${version.version} could not be found in the Flutter '
          'releases metadata.',
        );
      }

      return release;
    }

    throw const AppException(
      'Archive installation is supported only for Flutter channels and releases.',
    );
  }

  Future<_DownloadedArchive> _downloadArchive(FlutterSdkRelease release) async {
    final tempDir = await Directory.systemTemp.createTemp('fvm_archive_');
    final extension = release.archive.endsWith('.tar.xz') ? '.tar.xz' : '.zip';
    final archiveFile = File(path.join(tempDir.path, 'flutter$extension'));

    final client = HttpClient();
    final progress = logger.progress('Downloading Flutter SDK archive');

    Never cleanupAndRethrow(Object error, StackTrace stackTrace) {
      progress.fail('Failed to download Flutter SDK archive');
      tempDir.deleteSync(recursive: true);

      if (error is AppException) {
        Error.throwWithStackTrace(error, stackTrace);
      }

      Error.throwWithStackTrace(
        AppException('Failed to download Flutter SDK archive: $error'),
        stackTrace,
      );
    }

    try {
      final request = await client.getUrl(Uri.parse(release.archiveUrl));
      final response = await request.close();

      if (response.statusCode >= 400) {
        throw AppException(
          'Failed to download Flutter SDK archive: HTTP ${response.statusCode}.',
        );
      }

      final totalBytes = response.contentLength;
      final sink = archiveFile.openWrite();
      var downloaded = 0;

      try {
        await for (final chunk in response) {
          sink.add(chunk);
          downloaded += chunk.length;

          // contentLength returns -1 when unknown, not 0
          if (totalBytes != -1) {
            final percent = (downloaded / totalBytes * 100).clamp(0, 100);
            progress.update(
              'Downloading Flutter SDK archive (${percent.toStringAsFixed(1)}%)',
            );
          } else {
            progress.update(
              'Downloading Flutter SDK archive (${_formatBytes(downloaded)})',
            );
          }
        }
        await sink.close();
      } catch (e) {
        // Ensure sink is closed before cleanup to release file handles
        // Ignore close errors - we're already handling the original error
        await sink.close().catchError((_) => null);
        rethrow;
      }

      final description = totalBytes != -1
          ? _formatBytes(totalBytes)
          : _formatBytes(downloaded);
      progress.complete('Downloaded Flutter SDK archive ($description)');

      return _DownloadedArchive(file: archiveFile, tempDir: tempDir);
    } on SocketException catch (error, stackTrace) {
      cleanupAndRethrow(
        AppException(
          'Network error while downloading Flutter SDK archive: ${error.message}',
        ),
        stackTrace,
      );
    } on AppException catch (error, stackTrace) {
      cleanupAndRethrow(error, stackTrace);
    } catch (error, stackTrace) {
      cleanupAndRethrow(error, stackTrace);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _verifyChecksum(File archive, String expectedSha256) async {
    final progress = logger.progress('Verifying archive integrity');

    try {
      final digest = await sha256.bind(archive.openRead()).first;

      if (digest.toString().toLowerCase() != expectedSha256.toLowerCase()) {
        throw AppException(
          'Checksum verification failed for the downloaded Flutter archive. '
          'The file may be corrupted or tampered with.',
        );
      }

      progress.complete('Archive checksum verified');
    } on AppException {
      progress.fail('Archive checksum verification failed');
      rethrow;
    } catch (error, stackTrace) {
      progress.fail('Archive checksum verification failed');
      Error.throwWithStackTrace(
        AppException('Failed to verify archive checksum: $error'),
        stackTrace,
      );
    }
  }

  Future<void> _extractArchive(File archive, Directory targetDir) async {
    final progress = logger.progress('Extracting Flutter SDK archive');

    try {
      if (archive.path.endsWith('.tar.xz')) {
        await _extractTarXz(archive, targetDir);
      } else if (archive.path.endsWith('.zip')) {
        if (Platform.isWindows) {
          await _extractZipWindows(archive, targetDir);
        } else {
          await _extractZipUnix(archive, targetDir);
        }
      } else {
        throw AppException(
          'Unsupported archive format: ${path.extension(archive.path)}.',
        );
      }

      progress.complete('Flutter SDK archive extracted');
    } on AppException {
      progress.fail('Failed to extract Flutter SDK archive');
      rethrow;
    } catch (error, stackTrace) {
      progress.fail('Failed to extract Flutter SDK archive');
      Error.throwWithStackTrace(
        AppException('Failed to extract Flutter SDK archive: $error'),
        stackTrace,
      );
    }
  }

  Future<void> _extractTarXz(File archive, Directory targetDir) async {
    try {
      await get<ProcessService>().run(
        'tar',
        args: ['-xJf', archive.path, '-C', targetDir.path],
      );
    } on ProcessException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(
          'Failed to extract the archive with tar. Ensure the "tar" tool '
          'is available on your system. ${error.message}',
        ),
        stackTrace,
      );
    }
  }

  Future<void> _extractZipUnix(File archive, Directory targetDir) async {
    try {
      await get<ProcessService>().run(
        'unzip',
        args: ['-q', '-o', archive.path, '-d', targetDir.path],
      );
    } on ProcessException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(
          'Failed to extract the archive with unzip. Ensure the "unzip" tool '
          'is installed. ${error.message}',
        ),
        stackTrace,
      );
    }
  }

  /// Escapes a path for use in PowerShell single-quoted strings.
  String _escapePowerShellPath(String filePath) =>
      filePath.replaceAll("'", "''");

  Future<void> _extractZipWindows(File archive, Directory targetDir) async {
    // Use -LiteralPath with single quotes for proper path handling
    final escapedArchive = _escapePowerShellPath(archive.path);
    final escapedTarget = _escapePowerShellPath(targetDir.path);
    final command =
        "Expand-Archive -LiteralPath '$escapedArchive' -DestinationPath '$escapedTarget' -Force";

    try {
      await get<ProcessService>().run(
        'powershell',
        args: ['-NoLogo', '-NoProfile', '-Command', command],
      );
    } on ProcessException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(
          'Failed to extract the archive with PowerShell. ${error.message}',
        ),
        stackTrace,
      );
    }
  }

  void _flattenStructure(Directory targetDir) {
    final flutterDir = Directory(path.join(targetDir.path, 'flutter'));
    if (!flutterDir.existsSync()) {
      return;
    }

    for (final entity in flutterDir.listSync()) {
      final name = path.basename(entity.path);
      if (name == '__MACOSX') {
        continue;
      }

      final newPath = path.join(targetDir.path, name);

      try {
        entity.renameSync(newPath);
      } on FileSystemException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          AppException(
            'Failed to finalize extracted Flutter archive contents: '
            '${error.message}',
          ),
          stackTrace,
        );
      }
    }

    if (flutterDir.existsSync()) {
      flutterDir.deleteSync(recursive: true);
    }
  }

  void _removeMacOsMetadata(Directory targetDir) {
    final metadataDir = Directory(path.join(targetDir.path, '__MACOSX'));
    if (metadataDir.existsSync()) {
      try {
        metadataDir.deleteSync(recursive: true);
      } catch (e) {
        // Log but don't fail - macOS metadata cleanup is non-critical
        logger.debug('Failed to remove macOS metadata directory: $e');
      }
    }
  }

  void _validateExtraction(Directory targetDir) {
    final flutterExecPath =
        path.join(targetDir.path, 'bin', flutterExecFileName);
    if (!File(flutterExecPath).existsSync()) {
      throw const AppException(
        'The Flutter archive was extracted, but the flutter executable was '
        'not found. The archive structure may be invalid.',
      );
    }
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    if (bytes <= 0) {
      return '0 B';
    }

    var value = bytes.toDouble();
    var unit = 0;

    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }

    final precision = unit == 0 ? 0 : 1;

    return '${value.toStringAsFixed(precision)} ${units[unit]}';
  }

  /// Installs a Flutter SDK [version] by downloading and extracting
  /// its precompiled archive into [versionDir].
  Future<void> install(FlutterVersion version, Directory versionDir) async {
    _validateSupportedVersion(version);

    final release = await _resolveRelease(version);
    logger.debug(
      'Installing ${release.version} from archive: ${release.archiveUrl}',
    );

    if (versionDir.existsSync()) {
      versionDir.deleteSync(recursive: true);
    }
    versionDir.createSync(recursive: true);

    final download = await _downloadArchive(release);

    try {
      await _verifyChecksum(download.file, release.sha256);
      await _extractArchive(download.file, versionDir);
      _flattenStructure(versionDir);
      _removeMacOsMetadata(versionDir);
      _validateExtraction(versionDir);
    } finally {
      download.dispose();
    }
  }
}

class _DownloadedArchive {
  final File file;
  final Directory tempDir;

  const _DownloadedArchive({required this.file, required this.tempDir});

  void dispose() {
    if (!tempDir.existsSync()) {
      return;
    }

    try {
      tempDir.deleteSync(recursive: true);
    } catch (e) {
      // Log cleanup failure to stderr for visibility without blocking
      // Cannot use logger here since this is a simple data class
      stderr.writeln('Warning: Could not clean up temp directory: $e');
    }
  }
}
