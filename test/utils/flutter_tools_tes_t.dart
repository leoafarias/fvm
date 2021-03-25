@Timeout(Duration(minutes: 5))
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_tools.dart';
import 'package:fvm/src/workflows/install_version.workflow.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

// import '../test_helpers.dart';

void main() {
  // setUpAll(fvmSetUpAll);
  // tearDownAll(fvmTearDownAll);
  group('Flutter tools', () {
    test('Can run flutter', () async {
      try {
        await installWorkflow('stable');
        final flutterProject =
            await FlutterAppService.findAncestor(dir: kFlutterAppDir);
        await FlutterAppService.pinVersion(flutterProject, 'stable');

        await runFlutterCmd(flutterProject.pinnedVersion, ['--version']);
        expect(true, true);
      } on Exception {
        fail('Could not run flutter command');
      }
    });
  });
}
