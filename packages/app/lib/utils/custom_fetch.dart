import 'package:dio/dio.dart';

import 'package:dio_http_cache/dio_http_cache.dart';

Future<Map<String, dynamic>> customFetch(
    String url, Map<String, String> headers) async {
  final dio = Dio(BaseOptions(headers: headers));

  final response = await dio.get(
    url,
    options: buildCacheOptions(
      const Duration(hours: 4),
      primaryKey: 'http_fvm_cache',
    ),
  );
  return response.data;
}
