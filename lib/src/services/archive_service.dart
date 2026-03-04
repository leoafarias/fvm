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
  static const _supportedArchiveReleaseQualifiers = {'beta', 'dev'};
  static const _connectionTimeout = Duration(seconds: 30);
  static const _defaultResponseTimeout = Duration(seconds: 30);
  static const _defaultReadTimeout = Duration(seconds: 30);
  // Install operations can run through different ArchiveService instances,
  // so this lock map must be shared process-wide.
  static final Map<String, Future<void>> _inProcessInstallLocks = {};

  final Duration _responseTimeout;
  final Duration _readTimeout;

  const ArchiveService(
    super.context, {
    Duration responseTimeout = _defaultResponseTimeout,
    Duration readTimeout = _defaultReadTimeout,
  })  : _responseTimeout = responseTimeout,
        _readTimeout = readTimeout;

  static void validateArchiveInstallVersion(FlutterVersion version) {
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

    if (version.isChannel &&
        !_supportedArchiveChannels.contains(version.name)) {
      throw AppException(
        'Archive installation is available only for the stable, beta, or dev '
        'channels. Remove the --archive flag or choose a supported channel.',
      );
    }

    if (version.isRelease) {
      final releaseQualifier = version.releaseChannel?.name;
      if (releaseQualifier == FlutterChannel.stable.name) {
        throw const AppException(
          'Archive installation does not support the "@stable" qualifier. '
          'Use the version without a channel suffix, or use @beta/@dev.',
        );
      }

      if (releaseQualifier != null &&
          !_supportedArchiveReleaseQualifiers.contains(releaseQualifier)) {
        throw AppException(
          'Archive installation supports release qualifiers only for '
          '@beta and @dev. Received "@$releaseQualifier".',
        );
      }
    }

    if (!version.isChannel && !version.isRelease) {
      throw const AppException(
        'Archive installation is supported only for Flutter channels and releases.',
      );
    }
  }

  Future<FlutterSdkRelease> _resolveRelease(FlutterVersion version) async {
    final releaseClient = get<FlutterReleaseClient>();

    if (version.isChannel) {
      return releaseClient.getLatestChannelRelease(version.name);
    }

    if (version.isRelease) {
      final releaseQualifier = version.releaseChannel?.name;
      if (releaseQualifier != null) {
        final channelReleases =
            await releaseClient.getChannelReleases(releaseQualifier);
        for (final release in channelReleases) {
          if (release.version == version.version) {
            return release;
          }
        }

        throw AppException(
          'Release ${version.version} could not be found in the '
          '$releaseQualifier channel releases metadata.',
        );
      }

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

  void _finalizeInstall(
    Directory stagingDir,
    Directory versionDir,
    Directory backupDir,
  ) {
    var movedExistingVersion = false;

    try {
      if (versionDir.existsSync()) {
        versionDir.renameSync(backupDir.path);
        movedExistingVersion = true;
      }

      stagingDir.renameSync(versionDir.path);
    } on FileSystemException catch (error, stackTrace) {
      if (movedExistingVersion &&
          backupDir.existsSync() &&
          !versionDir.existsSync()) {
        try {
          backupDir.renameSync(versionDir.path);
        } on FileSystemException catch (restoreError) {
          Error.throwWithStackTrace(
            AppException(
              'Failed to finalize archive installation and restore the '
              'previous SDK cache. ${restoreError.message}',
            ),
            stackTrace,
          );
        }
      }

      Error.throwWithStackTrace(
        AppException(
          'Failed to finalize archive installation: ${error.message}',
        ),
        stackTrace,
      );
    }

    if (backupDir.existsSync()) {
      try {
        backupDir.deleteSync(recursive: true);
      } catch (cleanupError) {
        logger.debug(
          'Could not clean up archive backup directory: $cleanupError',
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds % 1000 == 0) {
      return '${duration.inSeconds}s';
    }

    return '${duration.inMilliseconds}ms';
  }

  Future<RandomAccessFile> _acquireInstallLock(File lockFile) async {
    if (!lockFile.parent.existsSync()) {
      lockFile.parent.createSync(recursive: true);
    }

    final lockHandle = await lockFile.open(mode: FileMode.writeOnlyAppend);

    try {
      await lockHandle.lock(FileLock.blockingExclusive);

      return lockHandle;
    } on FileSystemException catch (error, stackTrace) {
      try {
        await lockHandle.close();
      } catch (_) {
        // Best-effort cleanup before surfacing original lock error.
      }
      Error.throwWithStackTrace(
        AppException(
          'Failed to acquire archive install lock: ${error.message}',
        ),
        stackTrace,
      );
    }
  }

  Future<void> _releaseInstallLock(RandomAccessFile lockHandle) async {
    try {
      await lockHandle.unlock();
    } catch (error) {
      logger.debug('Failed to unlock archive install file: $error');
    }

    try {
      await lockHandle.close();
    } catch (error) {
      logger.debug('Failed to close archive install lock file: $error');
    }
  }

  Future<T> _withInProcessInstallLock<T>(
    String lockKey,
    Future<T> Function() action,
  ) async {
    final previousLock = _inProcessInstallLocks[lockKey];
    final lockCompleter = Completer<void>();
    _inProcessInstallLocks[lockKey] = lockCompleter.future;

    if (previousLock != null) {
      logger.debug('Waiting for in-process archive install lock: $lockKey');
      await previousLock;
    }

    try {
      return await action();
    } finally {
      lockCompleter.complete();
      if (identical(_inProcessInstallLocks[lockKey], lockCompleter.future)) {
        _inProcessInstallLocks.remove(lockKey);
      }
    }
  }

  Future<HttpClientResponse> _closeRequestWithTimeout(
    HttpClientRequest request, {
    required Never Function(Object, StackTrace) cleanupAndRethrow,
  }) async {
    try {
      return await request.close().timeout(_responseTimeout);
    } on TimeoutException catch (_, stackTrace) {
      cleanupAndRethrow(
        AppException(
          'Timed out while waiting for response from server after '
          '${_formatDuration(_responseTimeout)}. Please retry. If this '
          'keeps happening, check your network, proxy, or mirror '
          'configuration.',
        ),
        stackTrace,
      );
    }
  }

  Future<_DownloadedArchive> _downloadArchive(FlutterSdkRelease release) async {
    final tempDir = await Directory.systemTemp.createTemp('fvm_archive_');
    final extension = release.archive.endsWith('.tar.xz') ? '.tar.xz' : '.zip';
    final archiveFile = File(path.join(tempDir.path, 'flutter$extension'));

    final client = HttpClient()..connectionTimeout = _connectionTimeout;
    final progress = logger.progress('Downloading Flutter SDK archive');

    Never cleanupAndRethrow(Object error, StackTrace stackTrace) {
      progress.fail('Failed to download Flutter SDK archive');
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {
        // Best-effort cleanup; don't mask the original error
      }

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
      final response = await _closeRequestWithTimeout(
        request,
        cleanupAndRethrow: cleanupAndRethrow,
      );

      if (response.statusCode >= 400) {
        throw AppException(
          'Failed to download Flutter SDK archive: HTTP ${response.statusCode}.',
        );
      }

      final totalBytes = response.contentLength;
      final sink = archiveFile.openWrite();
      var downloaded = 0;

      try {
        await for (final chunk in response.timeout(_readTimeout)) {
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
      } on TimeoutException catch (_, stackTrace) {
        cleanupAndRethrow(
          AppException(
            'Timed out while waiting for download data after '
            '${_formatDuration(_readTimeout)}. Please retry. If this keeps '
            'happening, check your network, proxy, or mirror configuration.',
          ),
          stackTrace,
        );
      } finally {
        try {
          await sink.close();
        } catch (_) {
          // Best-effort stream cleanup.
        }
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
    } on HandshakeException catch (error, stackTrace) {
      cleanupAndRethrow(
        AppException(
          'TLS certificate verification failed while downloading Flutter SDK '
          'archive. If you are using a corporate mirror with a self-signed '
          'certificate, you may need to configure your system\'s certificate '
          'trust store. ${error.message}',
        ),
        stackTrace,
      );
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

  Future<void> _runExtraction(
    String tool,
    List<String> args,
    String errorHint,
  ) async {
    try {
      await get<ProcessService>().run(tool, args: args);
    } on ProcessException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException('$errorHint ${error.message}'),
        stackTrace,
      );
    }
  }

  Future<void> _extractTarXz(File archive, Directory targetDir) =>
      _runExtraction(
        'tar',
        ['-xJf', archive.path, '-C', targetDir.path],
        'Failed to extract the archive with tar. Ensure the "tar" tool '
            'is available on your system.',
      );

  Future<void> _extractZipUnix(File archive, Directory targetDir) =>
      _runExtraction(
        'unzip',
        ['-q', '-o', archive.path, '-d', targetDir.path],
        'Failed to extract the archive with unzip. Ensure the "unzip" tool '
            'is installed.',
      );

  /// Escapes a path for use in PowerShell single-quoted strings.
  String _escapePowerShellPath(String filePath) =>
      filePath.replaceAll("'", "''");

  Future<void> _extractZipWindows(File archive, Directory targetDir) {
    final escapedArchive = _escapePowerShellPath(archive.path);
    final escapedTarget = _escapePowerShellPath(targetDir.path);
    final command =
        "Expand-Archive -LiteralPath '$escapedArchive' -DestinationPath '$escapedTarget' -Force";

    return _runExtraction(
      'powershell',
      ['-NoLogo', '-NoProfile', '-Command', command],
      'Failed to extract the archive with PowerShell.',
    );
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

  String _readLinkTarget(Link entity) {
    try {
      return entity.targetSync();
    } on FileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppException(
          'Failed to inspect extracted symlink "${entity.path}": '
          '${error.message}',
        ),
        stackTrace,
      );
    }
  }

  void _validateSymlinkSafety(Directory targetDir) {
    final rootPath = path.normalize(targetDir.absolute.path);

    for (final entity
        in targetDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! Link) {
        continue;
      }

      final linkTarget = _readLinkTarget(entity);

      final resolvedTarget = path.normalize(
        path.isAbsolute(linkTarget)
            ? linkTarget
            : path.join(path.dirname(entity.path), linkTarget),
      );

      final isInside =
          resolvedTarget == rootPath || path.isWithin(rootPath, resolvedTarget);
      if (!isInside) {
        throw AppException(
          'The extracted Flutter archive contains a symlink that points '
          'outside the SDK directory: ${entity.path}.',
        );
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

  void _cleanupStagingDir(Directory stagingDir) {
    if (!stagingDir.existsSync()) {
      return;
    }

    try {
      stagingDir.deleteSync(recursive: true);
    } catch (cleanupError) {
      logger.debug(
        'Warning: Could not clean up staging directory: $cleanupError',
      );
    }
  }

  Future<void> _installLocked(
    FlutterVersion version,
    Directory versionDir,
  ) async {
    final lockFile = File('${versionDir.path}.archive_lock');
    logger.debug('Acquiring archive install lock: ${lockFile.path}');
    final lockHandle = await _acquireInstallLock(lockFile);

    try {
      final release = await _resolveRelease(version);
      logger.debug(
        'Installing ${release.version} from archive: ${release.archiveUrl}',
      );

      // Use a staging directory so an existing cache survives failures
      final stagingDir = Directory('${versionDir.path}.archive_staging');
      final backupDir = Directory('${versionDir.path}.archive_backup');

      if (stagingDir.existsSync()) {
        stagingDir.deleteSync(recursive: true);
      }

      // Recover from interrupted finalize: if a previous run was killed after
      // versionDir was moved to backupDir but before stagingDir took its place,
      // the backup is the only surviving copy. Restore it instead of deleting.
      if (backupDir.existsSync()) {
        if (!versionDir.existsSync()) {
          logger.debug(
            'Detected interrupted archive install – restoring backup.',
          );
          backupDir.renameSync(versionDir.path);
        } else {
          backupDir.deleteSync(recursive: true);
        }
      }

      final parentDir = versionDir.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      stagingDir.createSync(recursive: true);

      try {
        final download = await _downloadArchive(release);

        try {
          await _verifyChecksum(download.file, release.sha256);
          await _extractArchive(download.file, stagingDir);
          _flattenStructure(stagingDir);
          _removeMacOsMetadata(stagingDir);
          _validateSymlinkSafety(stagingDir);
          _validateExtraction(stagingDir);
        } finally {
          download.dispose();
        }

        _finalizeInstall(stagingDir, versionDir, backupDir);
      } catch (_) {
        _cleanupStagingDir(stagingDir);
        rethrow;
      }
    } finally {
      await _releaseInstallLock(lockHandle);
    }
  }

  /// Installs a Flutter SDK [version] by downloading and extracting
  /// its precompiled archive into [versionDir].
  ///
  /// Uses a staging directory to protect any existing cached version.
  /// If the install fails, the original [versionDir] is left untouched.
  Future<void> install(FlutterVersion version, Directory versionDir) async {
    validateArchiveInstallVersion(version);

    final lockKey = path.normalize(versionDir.absolute.path);
    await _withInProcessInstallLock(
      lockKey,
      () => _installLocked(version, versionDir),
    );
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
    } catch (_) {
      // Best-effort cleanup; outer install() handles its own staging cleanup
    }
  }
}
