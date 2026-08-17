import 'dart:convert';
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/tui/adapters/context_versions_repository.dart';
import 'package:fvm/src/tui/adapters/fvm_context_handle.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  test(
    'maps cached SDK, project, global, setup, and update metadata',
    () async {
      final context = TestFactory.context(
        generators: {FlutterReleaseClient: _FixtureReleaseClient.new},
      );
      _createSdk(context, 'stable', flutterVersion: '3.35.1', setup: true);
      _createSdk(context, '3.32.8', flutterVersion: '3.32.8', setup: true);
      _createSdk(
        context,
        'beta',
        flutterVersion: '3.35.0-0.1.pre',
        setup: false,
      );
      File(
        path.join(context.workingDirectory, '.fvmrc'),
      ).writeAsStringSync(jsonEncode({'flutter': '3.32.8'}));
      final cache = context.get<CacheService>();
      cache.setGlobal(cache.getVersion(FlutterVersion.channel('stable'))!);
      final handle = FvmContextHandle(context, reload: (previous) => previous);

      final data = await ContextVersionsRepository(handle).load();

      final project = data.items.singleWhere((item) => item.isProject);
      final global = data.items.singleWhere((item) => item.isGlobal);
      final beta = data.items.singleWhere((item) => item.id == 'beta');
      expect(project.version, '3.32.8');
      expect(global.version, '3.35.1');
      expect(global.channel, 'stable');
      expect(beta.needsSetup, isTrue);
      expect(data.items.map((item) => item.id), ['stable', 'beta', '3.32.8']);
      expect(data.cachePath, context.versionsCachePath);
      expect(data.cacheBytes, greaterThan(0));
      expect(data.updateMessage, contains('beta'));
      expect(data.updateMessage, contains('3.36.0-0.1.pre'));
    },
  );

  test('context handle reload replaces the context', () {
    final first = TestFactory.fastContext(debugLabel: 'first');
    final second = TestFactory.fastContext(debugLabel: 'second');
    final handle = FvmContextHandle(first, reload: (_) => second);

    handle.reloadFromDisk();

    expect(handle.current, same(second));
  });
}

void _createSdk(
  FvmContext context,
  String identity, {
  required String flutterVersion,
  required bool setup,
}) {
  final directory = Directory(path.join(context.versionsCachePath, identity))
    ..createSync(recursive: true);
  File(path.join(directory.path, 'bin', 'flutter'))
    ..createSync(recursive: true)
    ..writeAsStringSync('flutter');
  File(path.join(directory.path, 'version')).writeAsStringSync(flutterVersion);
  if (setup) {
    Directory(
      path.join(directory.path, 'bin', 'cache', 'dart-sdk', 'bin'),
    ).createSync(recursive: true);
  }
}

final class _FixtureReleaseClient extends FlutterReleaseClient {
  _FixtureReleaseClient(super.context);

  @override
  Future<FlutterReleasesResponse> fetchReleases({
    bool useCache = true,
    String? platform,
  }) async => FlutterReleasesResponse.fromMap({
    'base_url': 'https://example.invalid',
    'current_release': {
      'stable': 'stable-current',
      'beta': 'beta-current',
      'dev': 'dev-current',
    },
    'releases': [
      _release('stable-current', 'stable', '3.35.1'),
      _release('project', 'stable', '3.32.8'),
      _release('beta-cached', 'beta', '3.35.0-0.1.pre'),
      _release('beta-current', 'beta', '3.36.0-0.1.pre'),
      _release('dev-current', 'dev', '3.37.0-0.1.pre'),
    ],
  });
}

Map<String, Object> _release(String hash, String channel, String version) => {
  'archive': '$channel/flutter_$version.zip',
  'channel': channel,
  'dart_sdk_version': '3.9.0',
  'hash': hash,
  'release_date': '2026-08-01T00:00:00.000Z',
  'sha256': 'sha256-$hash',
  'version': version,
};
