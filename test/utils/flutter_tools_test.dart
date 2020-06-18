@Timeout(Duration(minutes: 5))
import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:fvm/utils/flutter_tools.dart';

void main() {
  group('Invalid Channels & Releases', () {
    test('Exception on invalid channel', () async {
      final invalidChannel = 'INVALID_CHANNEL';

      try {
        await flutterChannelClone(invalidChannel);
        fail('Exception not thrown');
      } on Exception catch (e) {
        expect(e, const TypeMatcher<ExceptionNotValidChannel>());
      }
    });

    test('Exception on invalid version', () async {
      final invalidVersion = 'INVALID_VERSION';

      try {
        await flutterVersionClone(invalidVersion);
        fail('Exception not thrown');
      } on Exception catch (e) {
        expect(e, const TypeMatcher<ExceptionNotValidVersion>());
      }
    });
    test('Checks that install is not correct', () async {
      final invalidVersionName = 'INVALID_VERSION';
      final dir = Directory(path.join(kVersionsDir.path, invalidVersionName));
      await dir.create(recursive: true);
      final correct = isInstalledCorrectly(invalidVersionName);
      expect(correct, false);
    });
  });

  test('Lists Flutter SDK Tags', () async {
    final flutterVersions = await flutterListAllSdks();
    final versionsExists = flutterVersions.contains('v1.8.0') &&
        flutterVersions.contains('v1.9.6') &&
        flutterVersions.contains('v1.10.5') &&
        flutterVersions.contains('v1.9.1+hotfix.4');
    expect(versionsExists, true);
  });
}
