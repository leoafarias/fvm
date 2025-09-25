import 'package:fvm/fvm.dart';
import 'package:fvm/src/commands/install_command.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  // Reusable test function for all version installations
  Future<void> testInstallVersion(String version) async {
    final runner = TestFactory.commandRunner();

    // Run the install command
    final exitCode = await runner.runOrThrow(['fvm', 'install', version]);

    // Get the installed version from cache
    final cacheVersion = runner.context.get<CacheService>().getVersion(
      FlutterVersion.parse(version),
    );

    // Determine the expected release channel
    String? releaseChannel;

    if (isFlutterChannel(version)) {
      releaseChannel = version;
    } else {
      if (cacheVersion!.releaseChannel != null) {
        releaseChannel = cacheVersion.releaseChannel!.name;
      } else {
        final release = await runner.context
            .get<FlutterReleaseClient>()
            .getReleaseByVersion(cacheVersion.version);

        if (cacheVersion.isUnknownRef) {
          releaseChannel = FlutterChannel.master.name;
        } else {
          releaseChannel = release!.channel.name;
        }
      }
    }

    // Get the actual branch from the installed version
    final existingChannel = await runner.context.get<GitService>().getBranch(
      version,
    );

    // Assertions
    expect(cacheVersion != null, true, reason: 'Install does not exist');
    expect(existingChannel, releaseChannel);
    expect(exitCode, ExitCode.success.code);
  }

  // Group 1: Flutter channels
  group('Install Flutter channels:', () {
    final channelVersions = ['master', 'stable', 'beta', 'dev'];

    for (var version in channelVersions) {
      test('Install $version channel', () async {
        await testInstallVersion(version);
      });
    }
  });

  // Group 2: Specific versions
  group('Install specific Flutter versions:', () {
    final specificVersions = ['2.0.0'];

    for (var version in specificVersions) {
      test('Install version $version', () async {
        await testInstallVersion(version);
      });
    }
  });

  // Group 3: Versions with specific channels
  group('Install versions with specific channels:', () {
    final versionWithChannels = ['2.2.2@beta', '2.2.2@dev'];

    for (var version in versionWithChannels) {
      test('Install $version', () async {
        await testInstallVersion(version);
      });
    }
  });

  // Group 4: Git commit hashes
  group('Install from Git commit hash:', () {
    final commitHashes = ['f4c74a6ec3'];

    for (var version in commitHashes) {
      test('Install commit $version', () async {
        await testInstallVersion(version);
      });
    }
  });

  // Group 5: Forked versions
  group('Fork validation in install command:', () {
    const testForkName = 'testfork';

    test('Validates fork exists in config', () async {
      final runner = TestFactory.commandRunner();

      // Try to install a version with a fork that's not configured
      expect(
        () => runner.runOrThrow(['fvm', 'install', '$testForkName/stable']),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains(
              'Fork "$testForkName" has not been configured',
            ),
          ),
        ),
      );
    });

    // Note: The tests for non-existent versions in forked repos aren't working
    // because the MockFlutterService in the test environment doesn't properly
    // simulate git errors. We need to handle these scenarios in real integration tests.
  });

  // Note: Additional tests for non-existent versions in the main repository
  // would also need to be added as integration tests rather than unit tests,
  // as the MockFlutterService doesn't properly simulate the git errors
  // we're trying to detect and handle.

  // Group 6: Install from project config
  group('Install from project config:', () {
    test('should install version from .fvmrc when no args', () async {
      // Create a temporary directory for this test
      final tempDir = createTempDir();

      try {
        // Create project with config
        createProjectConfig(ProjectConfig(flutter: '3.10.0'), tempDir);
        createPubspecYaml(tempDir);

        // Create runner with working directory
        final context = FvmContext.create(
          workingDirectoryOverride: tempDir.path,
          isTest: true,
        );
        final runner = TestCommandRunner(context);

        // Run install without arguments
        final exitCode = await runner.run(['fvm', 'install']);

        expect(exitCode, ExitCode.success.code);

        // Verify version was installed
        final cacheService = context.get<CacheService>();
        final version = FlutterVersion.parse('3.10.0');
        expect(cacheService.getVersion(version), isNotNull);
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('should throw when no args and no project config', () async {
      // Create a temporary directory without FVM config
      final tempDir = createTempDir();

      try {
        createPubspecYaml(tempDir);

        // Create runner with working directory
        final context = FvmContext.create(
          workingDirectoryOverride: tempDir.path,
          isTest: true,
        );
        final runner = TestCommandRunner(context);

        expect(
          () => runner.runOrThrow(['fvm', 'install']),
          throwsA(
            predicate<AppException>(
              (e) => e.message.contains(
                'Please provide a channel or a version, or run',
              ),
            ),
          ),
        );
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('should respect setup flag from command line', () async {
      // Create a temporary directory for this test
      final tempDir = createTempDir();

      try {
        // Create project with config
        createProjectConfig(ProjectConfig(flutter: 'stable'), tempDir);
        createPubspecYaml(tempDir);

        // Create runner with working directory
        final context = FvmContext.create(
          workingDirectoryOverride: tempDir.path,
          isTest: true,
        );
        final runner = TestCommandRunner(context);

        // Run install with setup flag
        final exitCode = await runner.run(['fvm', 'install', '--setup']);

        expect(exitCode, ExitCode.success.code);

        // Verify setup was run (project should be using the version)
        final project = context.get<ProjectService>().findAncestor();
        expect(project, isNotNull);
        expect(project.pinnedVersion?.name, 'stable');
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('invocation getter returns correct string', () {
      final context = FvmContext.create(isTest: true);
      final command = InstallCommand(context);
      expect(command.invocation, contains('fvm install {version}'));
      expect(command.invocation, contains('if no {version}'));
    });
  });
}
