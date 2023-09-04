import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/http.dart';
import 'package:test/test.dart';

void main() {
  group('Flutter Releases API', () {
    test('Has Channels', () async {
      final payload = await FlutterReleasesClient.get();
      final channels = payload.channels.toMap().keys;

      expect(channels.length, 3);
    });
    test('Has Flutter Releases', () async {
      final releases = await FlutterReleasesClient.get();
      final versionsExists = releases.containsVersion('v1.8.1') &&
          releases.containsVersion('v1.9.6') &&
          releases.containsVersion('v1.10.5') &&
          releases.containsVersion('v1.9.1+hotfix.4');
      expect(versionsExists, true);
    });

    test('Can fetch releases for all platforms', () async {
      try {
        await fetch(getReleasesUrl('macos'));
        await fetch(getReleasesUrl('linux'));
        await fetch(getReleasesUrl('windows'));
        expect(true, true);
      } on Exception {
        fail('Could not resolve all platform releases');
      }
    });
  });
}
