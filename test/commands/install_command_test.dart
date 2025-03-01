import 'package:fvm/fvm.dart';
import 'package:git/git.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

const versionList = [
  'f4c74a6ec3',
  '2.2.2@beta',
  '2.2.2@dev',
  'master',
  'stable',
  'beta',
  'dev',
  '2.0.0',
];
void main() {
  late TestCommandRunner runner;
  late FvmController controller;

  setUp(() {
    runner = TestFactory.commandRunner();
    controller = runner.controller;
  });

  group('Install workflow:', () {
    for (var version in versionList) {
      test('Install $version', () async {
        // Run the install command
        final exitCode = await runner.runOrThrow(['fvm', 'install', version]);

        // Get the installed version from cache
        final cacheVersion = controller.cache.getVersion(
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
            final release = await controller.releases.getReleaseFromVersion(
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
        final existingChannel =
            await getBranch(version, controller: controller);

        // Assertions
        expect(cacheVersion != null, true, reason: 'Install does not exist');
        expect(existingChannel, releaseChannel);
        expect(exitCode, ExitCode.success.code);
      });
    }
  });
}

// Assuming this function is in testing_utils.dart, it needs to be updated to accept a controller
Future<String?> getBranch(String version,
    {required FvmController controller}) async {
  // Implementation should check the branch of the installed version
  // This would typically access the Git branch information
  // Example implementation:
  final cacheVersion =
      controller.cache.getVersion(FlutterVersion.parse(version));
  if (cacheVersion == null) return null;

  // This is just a placeholder - you'll need to implement the actual Git branch checking logic
  final gitDir = await GitDir.fromExisting(cacheVersion.directory);
  final currentBranch = await gitDir.currentBranch();
  return currentBranch.branchName;
}
