@Tags(['network'])
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  test('live releases stay compatible with the fixture schema', () async {
    final context = TestFactory.context();
    final client = FlutterReleaseClient(context);
    final releases = await client.fetchReleases(useCache: false);

    expect(releases.baseUrl, isNotEmpty);
    expect(releases.versions, isNotEmpty);
    expect(releases.channels.toList, hasLength(3));

    for (final release in releases.versions) {
      expect(release.archive, isNotEmpty, reason: release.version);
      expect(release.channel.name, isNotEmpty, reason: release.version);
      expect(release.hash, isNotEmpty, reason: release.version);
      expect(release.releaseDate, isA<DateTime>(), reason: release.version);
      expect(release.sha256, isNotEmpty, reason: release.version);
      expect(release.version, isNotEmpty);
    }

    // dart_sdk_arch / dart_sdk_version are the SDK-metadata fields the minimal
    // fixture under-represents. Assert they still exist upstream so their
    // omission stays an intentional trim rather than a field that vanished.
    expect(
      releases.versions.any((release) => release.dartSdkArch != null),
      isTrue,
      reason: 'Live releases no longer expose dart_sdk_arch',
    );
    expect(
      releases.versions.any((release) => release.dartSdkVersion != null),
      isTrue,
      reason: 'Live releases no longer expose dart_sdk_version',
    );
  });
}
