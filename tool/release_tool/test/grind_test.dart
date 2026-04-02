import 'dart:convert';
import 'dart:io';

import '../tool/grind.dart' as grind;
import 'package:grinder/grinder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempRepo;

  setUp(() async {
    tempRepo = await Directory.systemTemp.createTemp('release_tool_test_');
    grind.repoRootOverride = tempRepo;
    grind.httpRequestOverride = null;
  });

  tearDown(() async {
    grind.repoRootOverride = null;
    grind.httpRequestOverride = null;
    if (await tempRepo.exists()) {
      await tempRepo.delete(recursive: true);
    }
  });

  group('getReleases', () {
    test('writes releases.txt for well-formed response', () async {
      grind.httpRequestOverride = (_) async => jsonEncode([
            {
              'tag_name': 'v1.0.0',
              'published_at': '2024-01-01T00:00:00Z',
            },
            {
              'tag_name': 'v0.9.0',
              'published_at': '2023-12-01T00:00:00Z',
            },
          ]);

      await grind.getReleases();

      final releasesFile = File(p.join(tempRepo.path, 'releases.txt'));
      expect(releasesFile.existsSync(), isTrue);
      final contents = releasesFile.readAsStringSync();
      expect(contents, contains('Release: v1.0.0, Date: 2024-01-01T00:00:00Z'));
      expect(contents, contains('Release: v0.9.0, Date: 2023-12-01T00:00:00Z'));
    });

    test('skips releases missing required fields', () async {
      grind.httpRequestOverride = (_) async => jsonEncode([
            {'tag_name': 'v1.0.0'},
            {
              'tag_name': 'v0.9.0',
              'published_at': '2023-12-01T00:00:00Z',
            },
          ]);

      await grind.getReleases();

      final contents =
          File(p.join(tempRepo.path, 'releases.txt')).readAsStringSync();
      expect(contents, isNot(contains('v1.0.0')));
      expect(contents, contains('v0.9.0'));
    });

    test('fails on invalid json', () async {
      grind.httpRequestOverride = (_) async => 'not-json';

      await expectLater(
        grind.getReleases(),
        throwsA(isA<GrinderException>()),
      );
    });
  });

  group('_githubRequest', () {
    test('returns body for 200 response', () async {
      final server = await HttpServer.bind('localhost', 0);
      addTearDown(server.close);

      server.listen((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('hello world')
          ..close();
      });

      final uri = Uri.parse('http://localhost:${server.port}/test');
      final body = await grind.githubRequestForTesting(uri);
      expect(body, 'hello world');
    });

    test('throws GrinderException for non-200 response', () async {
      final server = await HttpServer.bind('localhost', 0);
      addTearDown(server.close);

      server.listen((request) async {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('boom')
          ..close();
      });

      final uri = Uri.parse('http://localhost:${server.port}/test');
      expect(
        () => grind.githubRequestForTesting(uri),
        throwsA(isA<GrinderException>()),
      );
    });
  });
}
