import 'package:args/command_runner.dart';
import 'package:fvm/fvm.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

// Assuming this is defined in your testing_utils.dart
const _versionList = ['stable', 'beta', 'dev', '2.0.0'];

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
        expect(targetPath, versionDir.path);
        expect(linkExists, isTrue);
        expect(project.pinnedVersion?.name, version);
        expect(exitCode, ExitCode.success.code);
      });
    }
  });

  group('Pin functionality:', () {
    test('should pin channel to latest release', () async {
      final testDir = createTempDir();

      try {
        createPubspecYaml(testDir);

        // Create runner with working directory
        final context = FvmContext.create(
          workingDirectoryOverride: testDir.path,
          isTest: true,
        );
        final localRunner = TestCommandRunner(context);

        final exitCode = await localRunner.run([
          'fvm',
          'use',
          'stable',
          '--pin',
        ]);
        expect(exitCode, ExitCode.success.code);

        // Verify pinned to specific version, not channel
        final project = context.get<ProjectService>().findAncestor();
        expect(project.pinnedVersion?.name, isNot('stable'));
        expect(project.pinnedVersion?.name, matches(r'^\d+\.\d+\.\d+'));
      } finally {
        if (testDir.existsSync()) {
          testDir.deleteSync(recursive: true);
        }
      }
    });

    test('should fail gracefully for master channel', () async {
      final testDir = createTempDir();

      try {
        createPubspecYaml(testDir);

        // Create runner with working directory
        final context = FvmContext.create(
          workingDirectoryOverride: testDir.path,
          isTest: true,
        );
        final localRunner = TestCommandRunner(context);

        expect(
          () => localRunner.runOrThrow(['fvm', 'use', 'master', '--pin']),
          throwsA(
            predicate<UsageException>(
              (e) => e.message.contains(
                'Cannot pin a version that is not in dev, beta or stable',
              ),
            ),
          ),
        );
      } finally {
        if (testDir.existsSync()) {
          testDir.deleteSync(recursive: true);
        }
      }
    });

    test('pin flag throws error for specific versions', () async {
      final testDir = createTempDir();

      try {
        createPubspecYaml(testDir);

        // Create runner with working directory
        final context = FvmContext.create(
          workingDirectoryOverride: testDir.path,
          isTest: true,
        );
        final localRunner = TestCommandRunner(context);

        // Pinning a specific version should throw an error
        expect(
          () => localRunner.runOrThrow(['fvm', 'use', '3.10.0', '--pin']),
          throwsA(
            predicate<UsageException>(
              (e) => e.message.contains(
                'Cannot pin a version that is not in dev, beta or stable',
              ),
            ),
          ),
        );
      } finally {
        if (testDir.existsSync()) {
          testDir.deleteSync(recursive: true);
        }
      }
    });

    test('should fail for invalid channel', () async {
      final testDir = createTempDir();

      try {
        createPubspecYaml(testDir);

        // Create runner with working directory
        final context = FvmContext.create(
          workingDirectoryOverride: testDir.path,
          isTest: true,
        );
        final localRunner = TestCommandRunner(context);

        expect(
          () => localRunner.runOrThrow([
            'fvm',
            'use',
            'invalid-channel',
            '--pin',
          ]),
          throwsA(
            predicate<UsageException>(
              (e) => e.message.contains(
                'Cannot pin a version that is not in dev, beta or stable',
              ),
            ),
          ),
        );
      } finally {
        if (testDir.existsSync()) {
          testDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
