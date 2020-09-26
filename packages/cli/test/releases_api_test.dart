import 'package:fvm/src/releases_api/releases_client.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Flutter Releases API', () {
    test('Has Channels', () async {
      final payload = await fetchFlutterReleases();
      final channels = payload.channels;

      expect(channels.stable != null, true);
      expect(channels.beta != null, true);
      expect(channels.dev != null, true);
    });
    test('Has Flutter Releases', () async {
      final releases = await fetchFlutterReleases();
      final versionsExists = releases.containsVersion('v1.8.1') &&
          releases.containsVersion('v1.9.6') &&
          releases.containsVersion('v1.10.5') &&
          releases.containsVersion('v1.9.1+hotfix.4');
      expect(versionsExists, true);
    });

    test('Can fetch releases for all platforms', () async {
      try {
        await http.get(getReleasesUrl(platform: 'macos'));
        await http.get(getReleasesUrl(platform: 'linux'));
        await http.get(getReleasesUrl(platform: 'windows'));
        expect(true, true);
      } on Exception {
        fail('Could not resolve all platform releases');
      }
    });
  });
}
