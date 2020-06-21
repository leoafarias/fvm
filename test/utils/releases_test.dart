import 'package:fvm/fvm.dart';
import 'package:fvm/utils/releases_helper.dart';
@Timeout(Duration(minutes: 5))
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
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

  test('Can run releases', () async {
    try {
      await fvmRunner(['releases']);

      expect(true, true);
    } on Exception {
      rethrow;
    }
  });

  test('Can download release', () async {
    try {
      final releases = await fetchReleases();
      print(releases.toString());
      expect(true, true);
    } on Exception {
      rethrow;
    }
  });
}
