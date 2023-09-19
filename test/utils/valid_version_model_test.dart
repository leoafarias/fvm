import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:test/test.dart';

const longCommit = 'de25def7784a2e63a9e7d5cc50dff84db8f69298';
const shortCommit = 'de25def';

void main() {
  test('Valid Version behaves correctly', () async {
    final master = FlutterVersion.parse('master');
    final beta = FlutterVersion.parse('beta');
    final channelWithVersion = FlutterVersion.parse('2.2.2@beta');
    final version = FlutterVersion.parse('2.2.0');
    final gitCommit = FlutterVersion.parse(longCommit);
    final shortGitCommit = FlutterVersion.parse(shortCommit);

    // Check if its channel
    expect(master.isChannel, true);
    expect(beta.isChannel, true);
    expect(channelWithVersion.isChannel, false);
    expect(version.isChannel, false);
    expect(gitCommit.isChannel, false);
    expect(shortGitCommit.isChannel, false);

    // Check for correct vertsion
    expect(master.name, 'master');
    expect(beta.name, 'beta');
    expect(channelWithVersion.name, '2.2.2@beta');
    expect(channelWithVersion.version, '2.2.2');
    expect(channelWithVersion.releaseFromChannel, 'beta');
    expect(version.name, '2.2.0');
    expect(gitCommit.name, longCommit);
    expect(shortGitCommit.name, shortCommit);

    // Check if forces channel
    expect(master.releaseFromChannel, null);
    expect(beta.releaseFromChannel, null);
    expect(channelWithVersion.releaseFromChannel, 'beta');
    expect(version.releaseFromChannel, null);
    expect(gitCommit.releaseFromChannel, null);
    expect(shortGitCommit.releaseFromChannel, null);

    // Check if its master
    expect(master.isMaster, true);
    expect(beta.isMaster, false);
    expect(channelWithVersion.isMaster, false);
    expect(version.isMaster, false);
    expect(gitCommit.isMaster, false);
    expect(shortGitCommit.isMaster, false);

    // Check if its release
    expect(master.isRelease, false);
    expect(beta.isRelease, false);
    expect(channelWithVersion.isRelease, true);
    expect(version.isRelease, true);
    expect(gitCommit.isRelease, false);
    expect(shortGitCommit.isRelease, false);

    // Check if its commit
    expect(master.isCommit, false);
    expect(beta.isCommit, false);
    expect(channelWithVersion.isCommit, false);
    expect(version.isCommit, false);
    expect(gitCommit.isCommit, true);
    expect(shortGitCommit.isCommit, true);

    // Checks version
    expect(master.name, 'master');
    expect(beta.name, 'beta');
    expect(channelWithVersion.version, '2.2.2');
    expect(version.name, '2.2.0');
    expect(gitCommit.name, longCommit);
    expect(shortGitCommit.name, shortCommit);
  });
}
