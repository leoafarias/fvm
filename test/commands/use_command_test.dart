import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/extensions.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

// Assuming this is defined in your testing_utils.dart
const _versionList = [
  'stable',
  'beta',
  'dev',
  '2.0.0',
];

void main() {
  late TestCommandRunner runner;

  setUp(() {
    runner = TestFactory.commandRunner();
  });

  group('Use workflow:', () {
    for (var version in _versionList) {
      test('Use $version', () async {
        final exitCode = await runner.run([
          'fvm',
          'use',
          version,
          '--force',
          '--skip-setup',
        ]);

        // Get the project and verify its configuration
        final project = runner.context.get<ProjectService>().findAncestor();
        final link = project.localVersionSymlinkPath.link;
        final linkExists = link.existsSync();

        // Check the symlink target
        final targetPath = link.targetSync();
        final valid = FlutterVersion.parse(version);
        final versionDir =
            runner.context.get<CacheService>().getVersionCacheDir(valid);

        // Perform assertions
        expect(targetPath == versionDir.path, true);
        expect(linkExists, true);
        expect(project.pinnedVersion?.name, version);
        expect(exitCode, ExitCode.success.code);
      });
    }
  });
}
