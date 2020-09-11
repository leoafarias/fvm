@Timeout(Duration(minutes: 5))
import 'package:fvm/fvm.dart';

import 'package:fvm/src/flutter_tools/flutter_tools.dart';

import 'package:fvm/src/workflows/install_version.workflow.dart';
import 'package:test/test.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/src/flutter_tools/git_tools.dart';

import '../test_helpers.dart';

void main() {
  group('Flutter tools', () {
    test('Invalid Version/Channel Release', () async {
      final invalidVersion = 'INVALID_VERSION';

      try {
        await runGitClone(invalidVersion);
        fail('Exception not thrown');
      } on Exception catch (e) {
        expect(e, const TypeMatcher<InternalError>());
      }
    });

    test('Can run flutter', () async {
      try {
        await installWorkflow('stable');
        final flutterProject =
            await FlutterProjectRepo.findAncestor(dir: kFlutterAppDir);
        await FlutterProjectRepo.pinVersion(flutterProject, 'stable');

        await runFlutterCmd(flutterProject.pinnedVersion, ['--version']);
        expect(true, true);
      } on Exception {
        fail('Could not run flutter command');
      }
    });
  });
}
