@Timeout(Duration(minutes: 5))
// import 'package:fvm/utils/releases.dart';
import 'package:test/test.dart';
import 'package:dio/dio.dart';
// import 'package:fvm/utils/releases.dart';

void main() {
  test('Can fetch releases for all platforms', () async {
    String getPlatformUrl(String platform) {
      return 'https://storage.googleapis.com/flutter_infra/releases/releases_$platform.json';
    }

    try {
      await Dio().get(getPlatformUrl('macos'));
      await Dio().get(getPlatformUrl('linux'));
      await Dio().get(getPlatformUrl('windows'));
      expect(true, true);
    } on Exception {
      fail('Could not resolve all platform releases');
    }
  });

  // test('Can download release', () async {
  //   try {
  //     await downloadRelease('beta/macos/flutter_macos_1.19.0-4.1.pre-beta.zip');
  //     expect(true, true);
  //   } on Exception {
  //     rethrow;
  //   }
  // });
}
