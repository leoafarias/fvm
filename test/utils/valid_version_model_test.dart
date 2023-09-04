import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:test/test.dart';

void main() {
  test('Valid Version behaves correctly', () async {
    final master = FlutterVersion('master');
    final beta = FlutterVersion('beta');
    final channelWithVersion = FlutterVersion.fromString('2.2.2@beta');
    final version = FlutterVersion('2.2.0');
    final gitCommit = FlutterVersion('f4c74a6ec3');
    final shortGitCommit = FlutterVersion('97dd2ae');
    final gitHash = FlutterVersion('f4c74a6ec3');

    // Check if its channel
    expect(master.isChannel, true);
    expect(beta.isChannel, true);
    expect(channelWithVersion.isChannel, false);
    expect(version.isChannel, false);
    expect(gitCommit.isChannel, false);
    expect(shortGitCommit.isChannel, false);
    expect(gitHash.isChannel, false);

    // Check for correct vertsion
    expect(master.name, 'master');
    expect(beta.name, 'beta');
    expect(channelWithVersion.name, '2.2.2');
    expect(version.name, '2.2.0');
    expect(gitCommit.name, 'f4c74a6ec3');
    expect(shortGitCommit.name, '97dd2ae');
    expect(gitHash.name, 'f4c74a6ec3');

    // Check if forces channel
    expect(master.releaseChannel, null);
    expect(beta.releaseChannel, null);
    expect(channelWithVersion.releaseChannel, 'beta');
    expect(version.releaseChannel, null);
    expect(gitCommit.releaseChannel, null);
    expect(shortGitCommit.releaseChannel, null);
    expect(gitHash.releaseChannel, null);

    // Check if its master
    expect(master.isMaster, true);
    expect(beta.isMaster, false);
    expect(channelWithVersion.isMaster, false);
    expect(version.isMaster, false);
    expect(gitCommit.isMaster, false);
    expect(shortGitCommit.isMaster, false);
    expect(gitHash.isMaster, false);

    // Check if its release
    expect(master.isRelease, false);
    expect(beta.isRelease, false);
    expect(channelWithVersion.isRelease, true);
    expect(version.isRelease, true);
    expect(gitCommit.isRelease, false);
    expect(shortGitCommit.isRelease, false);
    expect(gitHash.isRelease, false);

    // Check if its commit
    expect(master.isCommit, false);
    expect(beta.isCommit, false);
    expect(channelWithVersion.isCommit, false);
    expect(version.isCommit, false);
    expect(gitCommit.isCommit, true);
    expect(shortGitCommit.isCommit, true);
    expect(gitHash.isCommit, true);

    // Checks version
    expect(master.name, 'master');
    expect(beta.name, 'beta');
    expect(channelWithVersion.name, '2.2.2');
    expect(version.name, '2.2.0');
    expect(gitCommit.name, 'f4c74a6ec3');
    expect(shortGitCommit.name, '97dd2ae');
    expect(gitHash.name, 'f4c74a6ec3');
  });
}
