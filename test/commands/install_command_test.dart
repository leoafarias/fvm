import 'package:fvm/fvm.dart';
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
            .getReleaseByVersion(
              cacheVersion.version,
            );

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
            (e) => e
                .toString()
                .contains('Fork "$testForkName" has not been configured'),
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

  // Group 6: Download flag functionality
  group('Download flag functionality:', () {
    test('Install command parses --download flag correctly', () {
      final runner = TestFactory.commandRunner();

      // Test that the command parses the --download flag without throwing
      expect(() {
        runner.parse(['install', 'stable', '--download']);
      }, returnsNormally);
    });

    test('Install command parses -d flag correctly', () {
      final runner = TestFactory.commandRunner();

      // Test that the command parses the -d flag without throwing
      expect(() {
        runner.parse(['install', 'stable', '-d']);
      }, returnsNormally);
    });

    test('Install command with --download flag is parsed correctly', () {
      final runner = TestFactory.commandRunner();

      // Test that the command with --download flag parses correctly
      final result = runner.parse(['install', '3.24.0', '--download']);
      expect(result.command?.name, equals('install'));
      expect(result.command?['download'], isTrue);
    });
  });
}
