import 'dart:convert';
import 'dart:io';

/// Does a simple get request on [url]
Future<String> fetch(String url, {Map<String, String>? headers}) async {
  final client = HttpClient();

  // Add headers to request

  final request = await client.getUrl(Uri.parse(url));

  // Add headers to request
  if (headers != null) {
    headers.forEach((key, value) {
      request.headers.set(key, value);
    });
  }

  final response = await request.close();

  if (response.statusCode >= 400) {
    throw HttpException(response.reasonPhrase);
  }

  final stream = response.transform(Utf8Decoder());

  var res = '';
  await for (final data in stream) {
    res += data;
  }

  return res;
}
