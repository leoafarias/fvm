import 'dart:io';

import 'package:fvm/fvm.dart';

import 'fixture_paths.dart';

/// Deterministic release metadata for fast tests.
class FakeFlutterReleaseClient extends FlutterReleaseClient {
  FakeFlutterReleaseClient(super.context);

  static final _fixturePath = packageFixturePath(
    'test/fixtures/releases/minimal_releases.json',
  );

  late final FlutterReleasesResponse _releases = loadFixtureReleases();

  static FlutterReleasesResponse loadFixtureReleases() {
    final file = File(_fixturePath);
    if (!file.existsSync()) {
      throw StateError('Missing releases fixture: $_fixturePath');
    }

    return FlutterReleasesResponse.fromJson(file.readAsStringSync());
  }

  @override
  Future<FlutterReleasesResponse> fetchReleases({
    bool useCache = true,
    String? platform,
  }) async {
    return _releases;
  }

  @override
  Future<List<FlutterSdkRelease>> getChannelReleases(String channelName) async {
    final response = await fetchReleases();

    return response.versions
        .where((release) => release.channel.name == channelName)
        .toList();
  }

  @override
  Future<bool> isVersionValid(String version) async {
    final normalized = version.startsWith('v') ? version.substring(1) : version;

    return _releases.containsVersion(normalized) ||
        _releases.containsVersion(version);
  }

  @override
  Future<FlutterSdkRelease> getLatestChannelRelease(String channel) async {
    return _releases.latestChannelRelease(channel);
  }

  @override
  Future<FlutterSdkRelease?> getReleaseByVersion(String version) async {
    final normalized = version.startsWith('v') ? version.substring(1) : version;

    return _releases.fromVersion(normalized) ?? _releases.fromVersion(version);
  }

  @override
  void clearCache() {}
}
