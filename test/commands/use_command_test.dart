@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  groupWithContext(
    'Use workflow:',
    () {
      final runner = TestCommandRunner();

      for (var version in kVersionList) {
        testWithContext(
          'Use $version',
          () async {
            final exitCode = await runner.run(
              'fvm use $version --force --skip-setup',
            );

            final project = ProjectService.fromContext.findAncestor();
            final link = project.localVersionSymlinkPath.link;
            final linkExists = link.existsSync();

            final targetPath = link.targetSync();
            final valid = FlutterVersion.parse(version);
            final versionDir =
                CacheService.fromContext.getVersionCacheDir(valid.name);

            expect(targetPath == versionDir.path, true);
            expect(linkExists, true);
            expect(project.pinnedVersion?.name, version);
            expect(exitCode, ExitCode.success.code);
          },
        );
      }
    },
  );
}
