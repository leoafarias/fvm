import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import '../utils/constants.dart';
import '../version.dart';
import 'base_service.dart';

typedef FvmReleaseRequest = Future<FvmReleaseHttpResponse> Function(
  Uri uri,
  Map<String, String> headers,
);

class FvmReleaseException implements Exception {
  final String message;

  const FvmReleaseException(this.message);

  @override
  String toString() => message;
}

class FvmReleaseHttpResponse {
  final int statusCode;
  final String body;

  const FvmReleaseHttpResponse({
    required this.statusCode,
    required this.body,
  });
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
  })  : _request = request ?? _httpRequest,
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

  static Future<FvmReleaseHttpResponse> _httpRequest(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers.forEach(request.headers.set);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      return FvmReleaseHttpResponse(
        statusCode: response.statusCode,
        body: body,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<FvmRelease> getLatestStableRelease() async {
    final FvmReleaseHttpResponse response;
    try {
      response =
          await _request(_releasesUri, _requestHeaders).timeout(_timeout);
    } on TimeoutException catch (_, stackTrace) {
      _throwReleaseException(
        'GitHub release request timed out after '
        '${_timeout.inSeconds} seconds.',
        stackTrace,
      );
    } on FvmReleaseException {
      rethrow;
    } catch (error, stackTrace) {
      _throwReleaseException(
        'GitHub release request failed: $error',
        stackTrace,
      );
    }

    if (response.statusCode != 200) {
      throw FvmReleaseException(
        'GitHub release request failed with status ${response.statusCode}.',
      );
    }

    final releases = _decodeReleaseList(response.body);
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
