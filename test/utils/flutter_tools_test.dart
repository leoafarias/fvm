@Timeout(Duration(minutes: 5))
import 'dart:io';
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/git_tools.dart';

import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('Invalid Channels & Releases', () {
    test('Invalid Version/Channel Release', () async {
      final invalidVersion = 'INVALID_VERSION';

      try {
        await runGitClone(invalidVersion);
        fail('Exception not thrown');
      } on Exception catch (e) {
        expect(e, const TypeMatcher<ExceptionCouldNotClone>());
      }
    });
    test('Checks that install is not correct', () async {
      final invalidVersionName = 'INVALID_VERSION';
      final dir = Directory(path.join(kVersionsDir.path, invalidVersionName));
      await dir.create(recursive: true);
      final correct =
          await LocalVersionRepo().ensureInstalledCorrectly(invalidVersionName);
      expect(correct, false);
    });
  });
}
