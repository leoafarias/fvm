import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/tui/adapters/context_releases_repository.dart';
import 'package:fvm/src/tui/adapters/fvm_context_handle.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  test('maps fixture releases in command display order', () async {
    final context = TestFactory.fastContext();
    _createSdk(context, '3.10.5');
    final expected = await context.get<FlutterReleaseClient>().fetchReleases();
    final repository = ContextReleasesRepository(
      FvmContextHandle(context, reload: (previous) => previous),
    );

    final releases = await repository.load();

    expect(
      releases.map((release) => release.version),
      expected.versions.reversed.map((release) => release.version),
    );
    final stable = releases.singleWhere(
      (release) => release.version == '3.10.5',
    );
    expect(stable.channel, 'stable');
    expect(stable.releaseDate, DateTime.utc(2024));
    expect(stable.dartSdkVersion, '3.0.0');
    expect(stable.architecture, isNull);
    expect(stable.activeChannel, isTrue);
    expect(stable.installed, isTrue);
  });
}

void _createSdk(FvmContext context, String version) {
  final directory = Directory(path.join(context.versionsCachePath, version))
    ..createSync(recursive: true);
  File(path.join(directory.path, 'bin', 'flutter'))
    ..createSync(recursive: true)
    ..writeAsStringSync('flutter');
  File(path.join(directory.path, 'version')).writeAsStringSync(version);
}
