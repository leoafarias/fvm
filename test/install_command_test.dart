@Timeout(Duration(minutes: 5))
import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  groupWithContext('Install workflow:', () {
    final runner = TestFvmCommandRunner();

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

    for (var version in versionList) {
      testWithContext(
        'Use $version',
        () async {
          final exitCode = await runner.run('fvm install $version');

          final cacheVersion =
              CacheService.instance.getVersion(FlutterVersion.parse(version));

          String? releaseChannel;

          if (kFlutterChannels.contains(version)) {
            releaseChannel = version;
          } else {
            if (cacheVersion!.releaseChannel != null) {
              releaseChannel = cacheVersion.releaseChannel;
            } else {
              final release = await FlutterReleasesClient.getReleaseFromVersion(
                cacheVersion.version,
              );

              if (cacheVersion.isCommit) {
                releaseChannel = FlutterChannel.master.name;
              } else {
                releaseChannel = release!.channel.name;
              }
            }
          }
          final existingChannel = await getBranch(version);
          expect(cacheVersion != null, true, reason: 'Install does not exist');

          expect(existingChannel, releaseChannel);
          expect(exitCode, ExitCode.success.code);
        },
      );
    }
  });
}
