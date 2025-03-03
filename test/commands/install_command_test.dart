import 'package:fvm/fvm.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  // Reusable test function for all version installations
  Future<void> testInstallVersion(String version) async {
    final runner = TestFactory.commandRunner();
    final services = runner.services;

    // Run the install command
    final exitCode = await runner.runOrThrow(['fvm', 'install', version]);

    // Get the installed version from cache
    final cacheVersion = services.cache.getVersion(
      FlutterVersion.parse(version),
    );

    // Determine the expected release channel
    String? releaseChannel;

    if (isFlutterChannel(version)) {
      releaseChannel = version;
    } else {
      if (cacheVersion!.releaseFromChannel != null) {
        releaseChannel = cacheVersion.releaseFromChannel;
      } else {
        final release = await services.releases.getReleaseFromVersion(
          cacheVersion.version,
        );

        if (cacheVersion.isCommit) {
          releaseChannel = FlutterChannel.master.name;
        } else {
          releaseChannel = release!.channel.name;
        }
      }
    }

    // Get the actual branch from the installed version
    final existingChannel = await services.git.getBranch(
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
}
