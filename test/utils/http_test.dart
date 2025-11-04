import 'dart:async';
import 'dart:io';

import 'package:fvm/src/utils/http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements HttpClient {}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  group('httpRequest', () {
    test('throws HttpException with URL on 404', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        request.response
          ..statusCode = HttpStatus.notFound
          ..reasonPhrase = 'Not Found';
        await request.response.close();
      });

      final url =
          'http://${server.address.host}:${server.port}/resource-does-not-exist';

      await expectLater(
        httpRequest(url),
        throwsA(
          isA<HttpException>().having(
            (e) => e.message,
            'message',
            allOf(contains('404'), contains(url)),
          ),
        ),
      );
    });

    test('closes client on error', () async {
      final client = _MockHttpClient();
      final request = _MockHttpClientRequest();

      when(() => client.getUrl(any())).thenAnswer((_) async => request);
      when(() => request.close()).thenThrow(const SocketException('failure'));
      when(() => client.close(force: any(named: 'force'))).thenAnswer((_) {});

      await expectLater(
        HttpOverrides.runZoned(
          () => httpRequest('https://example.com'),
          createHttpClient: (_) => client,
        ),
        throwsA(isA<SocketException>()),
      );

      verify(() => client.close(force: false)).called(1);
    });

    test('passes custom headers to request', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      final capturedHeaders = Completer<HttpHeaders>();

      server.listen((request) async {
        capturedHeaders.complete(request.headers);
        request.response
          ..statusCode = HttpStatus.ok
          ..write('ok');
        await request.response.close();
      });

      final url = 'http://${server.address.host}:${server.port}/';
      final response = await httpRequest(url, headers: {
        'Authorization': 'Bearer token',
        'Accept': 'application/json',
      });

      expect(response, equals('ok'));

      final headers = await capturedHeaders.future;
      expect(headers.value('authorization'), 'Bearer token');
      expect(headers.value('accept'), 'application/json');
    });

    test('throws FormatException for malformed URL', () {
      expect(
        () => httpRequest('://malformed-url'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
