@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  groupWithContext(
    'Use workflow:',
    () {
      final runner = TestFvmCommandRunner();

      for (var version in kVersionList) {
        testWithContext(
          'Use $version',
          () async {
            final exitCode = await runner.run(
              'fvm use $version --force --skip-setup',
            );

            final project = await ProjectService.instance.findAncestor();
            final linkExists = project.cacheVersionSymlink.existsSync();

            final targetPath = project.cacheVersionSymlink.targetSync();
            final valid = FlutterVersion.parse(version);
            final versionDir =
                CacheService.instance.getVersionCacheDir(valid.name);

            expect(targetPath == versionDir.path, true);
            expect(linkExists, true);
            expect(project.pinnedVersion, version);
            expect(exitCode, ExitCode.success.code);
          },
        );
      }
    },
  );
}
