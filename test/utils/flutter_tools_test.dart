@Timeout(Duration(minutes: 5))
import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:test/test.dart';
import 'package:fvm/utils/flutter_tools.dart';

void main() {
  final channel = 'master';
  final version = '1.8.0';

  test('Clones a "master" channel', () async {
    // Clones version
    await flutterChannelClone(channel);
    // Check if SDK Version matches cloned
    final existingChannel = await flutterSdkVersion(channel);
    expect(existingChannel, channel);
  });

  test('Clones a version', () async {
    // await flutterSdkRemove(version);
    await flutterVersionClone(version);
    final existingVersion = await flutterSdkVersion(version);
    expect(existingVersion, 'v$version');
  });

  // test('Channel has already been cloned', () async {
  //   final channelClone = await flutterChannelClone(channel);
  //   expect(channelClone['existed'], true);
  // });

  // test('Version has already been cloned', () async {
  //   final versionClone = await flutterVersionClone(version);
  //   expect(versionClone['existed'], true);
  // });

  test('Exception on invalid channel', () async {
    final invalidChannel = 'INVALID_CHANNEL';

    try {
      await flutterChannelClone(invalidChannel);
      fail("Exception not thrown");
    } on Exception catch (e) {
      expect(e, TypeMatcher<ExceptionNotValidChannel>());
    }
  });

  test('Clones a "version" from tag', () async {
    await flutterVersionClone(version);
    final versionExists = await flutterSdkVersion(version);
    expect(versionExists, 'v$version');
  });

  test('Exception on invalid version', () async {
    final invalidVersion = 'INVALID_VERSION';

    try {
      await flutterVersionClone(invalidVersion);
      fail("Exception not thrown");
    } on Exception catch (e) {
      expect(e, TypeMatcher<ExceptionNotValidVersion>());
    }
  });

  test('Gets correct version from channel', () async {
    final channelExists = await flutterSdkVersion(channel);
    expect(channelExists, channel);
  });

  test('Gets correct version from tag', () async {
    final versionExists = await flutterSdkVersion(version);
    expect(versionExists, 'v$version');
  });

  test('Lists existing Flutter SDK Versions', () async {
    final flutterVersions = await flutterListAllSdks();
    final versionsExists = flutterVersions.contains('v1.8.0') &&
        flutterVersions.contains('v1.9.6') &&
        flutterVersions.contains('v1.10.5') &&
        flutterVersions.contains('v1.9.1+hotfix.4');
    expect(versionsExists, true);
  });

  test('Lists Installed Fluuter SDKs', () async {
    final installedVersions = await flutterListInstalledSdks();
    final installExists = installedVersions.contains(channel) &&
        installedVersions.contains(version);
    expect(installExists, true);
  });

  test('Links Flutter project to correct version', () async {
    await linkProjectFlutterDir(channel);

    /// Check that it exists
    final linkExists = await kLocalFlutterLink.exists();

    final targetBin = await kLocalFlutterLink.target();

    final versionBin = '${kVersionsDir.path}/$channel/bin/flutter';

    expect(targetBin == versionBin, true);
    expect(linkExists, true);
  });
}
