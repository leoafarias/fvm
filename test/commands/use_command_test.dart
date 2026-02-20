import 'package:args/command_runner.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_service.dart';
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
        expect(targetPath, equals(versionDir.path));
        expect(linkExists, isTrue);
        expect(project.pinnedVersion?.name, version);
        expect(exitCode, ExitCode.success.code);
      });
    }
  });

  group('Archive flag:', () {
    test('uses stable channel via archive', () async {
      final context = TestFactory.context();
      final localRunner = TestCommandRunner(context);

      final exitCode = await localRunner.run([
        'fvm',
        'use',
        'stable',
        '--archive',
        '--force',
        '--skip-setup',
        '--skip-pub-get',
      ]);

      final flutterService =
          context.get<FlutterService>() as MockFlutterService;

      expect(exitCode, ExitCode.success.code);
      expect(flutterService.lastUseArchive, isTrue);
      expect(flutterService.lastInstallVersion?.name, 'stable');
      expect(flutterService.lastInstallDirectory, isNotNull);
      expect(flutterService.lastInstallDirectory!.existsSync(), isTrue);
    });

    test('fails for unsupported channels', () async {
      final localRunner = TestFactory.commandRunner();

      expect(
        () => localRunner.runOrThrow([
          'fvm',
          'use',
          'master',
          '--archive',
          '--skip-setup',
          '--skip-pub-get',
        ]),
        throwsA(
          predicate<AppException>(
            (error) => error.message.contains('stable, beta, or dev channels'),
          ),
        ),
      );
    });

    test('fails for @stable qualifiers', () async {
      final localRunner = TestFactory.commandRunner();

      expect(
        () => localRunner.runOrThrow([
          'fvm',
          'use',
          '2.2.2@stable',
          '--archive',
          '--skip-setup',
          '--skip-pub-get',
        ]),
        throwsA(
          predicate<AppException>(
            (error) => error.message.contains(
              'does not support the "@stable" qualifier',
            ),
          ),
        ),
      );
    });

    test('fails for unsupported release qualifiers', () async {
      final localRunner = TestFactory.commandRunner();

      expect(
        () => localRunner.runOrThrow([
          'fvm',
          'use',
          '2.2.2@master',
          '--archive',
          '--skip-setup',
          '--skip-pub-get',
        ]),
        throwsA(
          predicate<AppException>(
            (error) => error.message.contains('@beta and @dev'),
          ),
        ),
      );
    });
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
