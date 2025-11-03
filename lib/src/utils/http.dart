import 'dart:convert';
import 'dart:io';

/// Does a simple get request on [url]
Future<String> httpRequest(String url, {Map<String, String>? headers}) async {
  final client = HttpClient();

  try {
    final request = await client.getUrl(Uri.parse(url));

    headers?.forEach(request.headers.set);

    final response = await request.close();

    if (response.statusCode >= 400) {
      var guidance = '';
      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        guidance = ' Check your authentication credentials.';
      } else if (response.statusCode == HttpStatus.notFound) {
        guidance = ' The requested resource was not found.';
      } else if (response.statusCode >= HttpStatus.internalServerError) {
        guidance = ' The server encountered an error. Try again later.';
      }

      throw HttpException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase} - URL: $url.$guidance',
      );
    }

    final stream = response.transform(const Utf8Decoder());
    final buffer = StringBuffer();
    await for (final data in stream) {
      buffer.write(data);
    }

    return buffer.toString();
  } finally {
    client.close();
  }
}
