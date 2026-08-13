import 'dart:async';
import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';

import '../utils/constants.dart';
import '../utils/exceptions.dart';
import '../utils/http.dart';
import '../version.dart';
import 'base_service.dart';

typedef FvmReleaseRequest = Future<String> Function(
  Uri uri,
  Map<String, String> headers,
);

class FvmReleaseException extends AppException {
  const FvmReleaseException(super.message);
}

class FvmRelease {
  final Version version;
  final Uri url;

  const FvmRelease({required this.version, required this.url});
}

class FvmReleaseService extends ContextualService {
  static final _defaultReleasesUri = Uri.https(
    'api.github.com',
    '/repos/$kFvmRepository/releases',
    {'per_page': '100'},
  );
  static const _requestHeaders = {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'fvm/$packageVersion',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  final FvmReleaseRequest _request;
  final Uri _releasesUri;
  final Duration _timeout;

  FvmReleaseService(
    super.context, {
    FvmReleaseRequest? request,
    Uri? releasesUri,
    Duration timeout = const Duration(seconds: 5),
  })  : _request = request ??
            ((uri, headers) => httpRequest(uri.toString(), headers: headers)),
        _releasesUri = releasesUri ?? _defaultReleasesUri,
        _timeout = timeout;

  static Never _throwReleaseException(String message, StackTrace stackTrace) {
    Error.throwWithStackTrace(FvmReleaseException(message), stackTrace);
  }

  static List<Object?> _decodeReleaseList(String body) {
    try {
      final decoded = jsonDecode(body);

      return decoded is List ? decoded : const [];
    } on FormatException catch (_, stackTrace) {
      _throwReleaseException(
        'GitHub release response contained invalid JSON.',
        stackTrace,
      );
    }
  }

  static FvmRelease? _parseRelease(Object? entry) {
    if (entry is! Map<String, dynamic> ||
        entry['draft'] != false ||
        entry['prerelease'] != false) {
      return null;
    }

    final tag = entry['tag_name'];
    final url = entry['html_url'];
    if (tag is! String || url is! String) return null;

    final releaseUrl = Uri.tryParse(url);
    if (releaseUrl == null ||
        releaseUrl.scheme != 'https' ||
        releaseUrl.host != 'github.com' ||
        !releaseUrl.path.startsWith('/$kFvmRepository/releases/tag/')) {
      return null;
    }

    final normalizedTag = tag.startsWith('v') ? tag.substring(1) : tag;
    try {
      final version = Version.parse(normalizedTag);
      if (version.isPreRelease) return null;

      return FvmRelease(version: version, url: releaseUrl);
    } on FormatException {
      return null;
    }
  }

  Future<FvmRelease> getLatestStableRelease() async {
    final String body;
    try {
      body = await _request(_releasesUri, _requestHeaders).timeout(_timeout);
    } on TimeoutException catch (_, stackTrace) {
      _throwReleaseException(
        'GitHub release request timed out after '
        '${_timeout.inSeconds} seconds.',
        stackTrace,
      );
    } catch (error, stackTrace) {
      _throwReleaseException(
        'GitHub release request failed: $error',
        stackTrace,
      );
    }

    final releases = _decodeReleaseList(body);
    FvmRelease? latest;

    for (final entry in releases) {
      final release = _parseRelease(entry);
      if (release != null &&
          (latest == null || release.version > latest.version)) {
        latest = release;
      }
    }

    if (latest == null) {
      throw const FvmReleaseException(
        'GitHub response did not contain a stable FVM CLI release.',
      );
    }

    return latest;
  }
}
