import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late FVMContext context;

  setUp(() {
    context = TestFactory.context();
  });

  group('Flutter Releases API', () {
    test('Has Flutter Releases', () async {
      final flutterReleases = FlutterReleasesService(context);
      final releases = await flutterReleases.getReleases();
      final versionsExists = releases.containsVersion('v1.8.1') &&
          releases.containsVersion('v1.9.6') &&
          releases.containsVersion('v1.10.5') &&
          releases.containsVersion('v1.9.1+hotfix.4');
      final channels = releases.channels.toMap().keys;

      expect(versionsExists, true);
      expect(channels.length, 3);
    });

    // test('Can fetch releases for all platforms', () async {
    //   try {
    //     await Future.wait([
    //       fetch(getReleasesUrl('macos')),
    //       fetch(getReleasesUrl('linux')),
    //       fetch(getReleasesUrl('windows')),
    //     ]);

    //     expect(true, true);
    //   } on Exception catch (err) {
    //     fail('Could not resolve all platform releases \n $err');
    //   }
    // });
  });
}
