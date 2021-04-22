import 'dart:convert';
import 'dart:io';

/// Does a simple get request on [url]
Future<String> fetch(String url) async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(url));

  final response = await request.close();

  final stream = response.transform(Utf8Decoder());

  var res = '';
  await for (final data in stream) {
    res += data;
  }

  return res;
}
