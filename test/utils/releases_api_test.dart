import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late FvmContext context;

  setUp(() {
    context = TestFactory.context();
  });

  group('Flutter Releases API', () {
    test('Has Flutter Releases', () async {
      final flutterReleases = FlutterReleaseClient(context);
      final releases = await flutterReleases.fetchReleases();
      final versionsExists = releases.containsVersion('v1.8.1') &&
          releases.containsVersion('v1.9.6') &&
          releases.containsVersion('v1.10.5') &&
          releases.containsVersion('v1.9.1+hotfix.4');
      final channels = releases.channels.toMap().keys;

      expect(versionsExists, true);
      expect(channels.length, 3);
    });
  });
}
