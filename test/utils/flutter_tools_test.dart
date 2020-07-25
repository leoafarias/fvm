@Timeout(Duration(minutes: 5))
import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/flutter/flutter_releases.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:fvm/flutter/flutter_tools.dart';

void main() {
  group('Invalid Channels & Releases', () {
    test('Invalid Version/Channel Release', () async {
      final invalidVersion = 'INVALID_VERSION';

      try {
        await gitCloneCmd(invalidVersion);
        fail('Exception not thrown');
      } on Exception catch (e) {
        expect(e, const TypeMatcher<ExceptionCouldNotClone>());
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
    final releases = await getReleases();
    final versionsExists = releases.containsVersion('v1.8.1') &&
        releases.containsVersion('v1.9.6') &&
        releases.containsVersion('v1.10.5') &&
        releases.containsVersion('v1.9.1+hotfix.4');
    expect(versionsExists, true);
  });
}
