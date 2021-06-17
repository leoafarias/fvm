import 'package:fvm/src/models/valid_version_model.dart';
import 'package:test/test.dart';

void main() {
  test('Valid Version behaves correctly', () async {
    final master = ValidVersion('master');
    final beta = ValidVersion('beta');
    final channelWithVersion = ValidVersion('beta@2.2.2');
    final version = ValidVersion('2.2.0');
    final gitHash = ValidVersion('f4c74a6ec3');

    // Check if its channel
    expect(master.isChannel, true);
    expect(beta.isChannel, true);
    expect(channelWithVersion.isChannel, false);
    expect(version.isChannel, false);
    expect(gitHash.isChannel, false);

    // Check for correct vertsion
    expect(master.version, 'master');
    expect(beta.version, 'beta');
    expect(channelWithVersion.version, '2.2.2');
    expect(version.version, '2.2.0');
    expect(gitHash.version, 'f4c74a6ec3');

    // Check if forces channel
    expect(master.forceChannel, null);
    expect(beta.forceChannel, null);
    expect(channelWithVersion.forceChannel, 'beta');
    expect(version.forceChannel, null);
    expect(gitHash.forceChannel, null);

    // Check if its master
    expect(master.isMaster, true);
    expect(beta.isMaster, false);
    expect(channelWithVersion.isMaster, false);
    expect(version.isMaster, false);
    expect(gitHash.isMaster, false);

    // Check if its release
    expect(master.isRelease, false);
    expect(beta.isRelease, false);
    expect(channelWithVersion.isRelease, true);
    expect(version.isRelease, true);
    expect(gitHash.isRelease, false);

    // Check if needs reset
    expect(master.needReset, false);
    expect(beta.needReset, false);
    expect(channelWithVersion.needReset, true);
    expect(version.needReset, true);
    expect(gitHash.needReset, true);
  });
}
