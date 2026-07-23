import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/services/fvm_release_service.dart';
import 'package:fvm/src/version.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  test('is available from the FVM context', () {
    final context = TestFactory.fastContext();

    expect(context.get<FvmReleaseService>(), isA<FvmReleaseService>());
  });

  test('returns the greatest stable FVM CLI release', () async {
    late Uri requestedUri;
    late Map<String, String> requestedHeaders;
    final service = FvmReleaseService(
      TestFactory.fastContext(),
      request: (uri, headers) async {
        requestedUri = uri;
        requestedHeaders = headers;

        return FvmReleaseHttpResponse(
          statusCode: 200,
          body: jsonEncode([
            _releaseJson('4.2.0'),
            _releaseJson('fvm-mcp-v9.0.0'),
            _releaseJson('5.1.0-beta.1', prerelease: true),
            _releaseJson('9.0.0', draft: true),
            _releaseJson('v5.0.0'),
            _releaseJson('not-a-version'),
            {..._releaseJson('99.0.0'), 'html_url': '/relative-release-url'},
          ]),
        );
      },
    );

    final release = await service.getLatestStableRelease();

    expect(release.version, Version(5, 0, 0));
    expect(
      release.url,
      Uri.parse('https://github.com/conceptadev/fvm/releases/tag/5.0.0'),
    );
    expect(requestedUri.host, 'api.github.com');
    expect(requestedUri.path, '/repos/conceptadev/fvm/releases');
    expect(requestedUri.queryParameters['per_page'], '100');
    expect(requestedHeaders['Accept'], 'application/vnd.github+json');
    expect(requestedHeaders['X-GitHub-Api-Version'], '2022-11-28');
    expect(requestedHeaders['User-Agent'], 'fvm/$packageVersion');
  });

  test('rejects a non-successful GitHub response', () async {
    final service = FvmReleaseService(
      TestFactory.fastContext(),
      request: (_, __) async => FvmReleaseHttpResponse(
        statusCode: 500,
        body: jsonEncode([_releaseJson('99.0.0')]),
      ),
    );

    expect(
      service.getLatestStableRelease,
      throwsA(
        isA<FvmReleaseException>().having(
          (error) => error.message,
          'message',
          contains('status 500'),
        ),
      ),
    );
  });

  test('reports malformed GitHub JSON as a release failure', () async {
    final service = FvmReleaseService(
      TestFactory.fastContext(),
      request: (_, __) async => const FvmReleaseHttpResponse(
        statusCode: 200,
        body: 'not-json',
      ),
    );

    expect(
      service.getLatestStableRelease,
      throwsA(
        isA<FvmReleaseException>().having(
          (error) => error.message,
          'message',
          contains('invalid JSON'),
        ),
      ),
    );
  });

  test('rejects a response without a stable FVM CLI release', () async {
    final service = FvmReleaseService(
      TestFactory.fastContext(),
      request: (_, __) async => FvmReleaseHttpResponse(
        statusCode: 200,
        body: jsonEncode([
          _releaseJson('fvm-mcp-v1.0.0'),
          _releaseJson('5.0.0-beta.1'),
        ]),
      ),
    );

    expect(
      service.getLatestStableRelease,
      throwsA(
        isA<FvmReleaseException>().having(
          (error) => error.message,
          'message',
          contains('stable FVM CLI release'),
        ),
      ),
    );
  });

  test('rejects an empty GitHub release list', () async {
    final service = FvmReleaseService(
      TestFactory.fastContext(),
      request: (_, __) async => const FvmReleaseHttpResponse(
        statusCode: 200,
        body: '[]',
      ),
    );

    expect(
      service.getLatestStableRelease,
      throwsA(isA<FvmReleaseException>()),
    );
  });

  test('reports a bounded request timeout as a release failure', () async {
    final pendingResponse = Completer<FvmReleaseHttpResponse>();
    final service = FvmReleaseService(
      TestFactory.fastContext(),
      request: (_, __) => pendingResponse.future,
      timeout: Duration.zero,
    );

    expect(
      service.getLatestStableRelease,
      throwsA(
        isA<FvmReleaseException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });

  test('reports transport errors as release failures', () async {
    final service = FvmReleaseService(
      TestFactory.fastContext(),
      request: (_, __) async => throw const SocketException('offline'),
    );

    expect(
      service.getLatestStableRelease,
      throwsA(
        isA<FvmReleaseException>().having(
          (error) => error.message,
          'message',
          contains('request failed'),
        ),
      ),
    );
  });

  test('uses the default HTTP transport', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode([_releaseJson('5.0.0')]))
        ..close();
    });
    final service = FvmReleaseService(
      TestFactory.fastContext(),
      releasesUri: Uri.parse(
        'http://${server.address.host}:${server.port}/releases?per_page=100',
      ),
    );

    final release = await service.getLatestStableRelease();

    expect(release.version, Version(5, 0, 0));
  });
}

Map<String, Object> _releaseJson(
  String tag, {
  bool draft = false,
  bool prerelease = false,
}) {
  return {
    'tag_name': tag,
    'html_url':
        'https://github.com/conceptadev/fvm/releases/tag/${tag.replaceFirst('v', '')}',
    'draft': draft,
    'prerelease': prerelease,
  };
}
