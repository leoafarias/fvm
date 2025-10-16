import 'dart:convert';
import 'dart:io';

/// Does a simple get request on [url]
Future<String> httpRequest(String url, {Map<String, String>? headers}) async {
  final client = HttpClient();

  try {
    final request = await client.getUrl(Uri.parse(url));

    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
    }

    final response = await request.close();

    if (response.statusCode >= 400) {
      throw HttpException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase} - URL: $url',
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
