import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:http/http.dart' as http;

// ignore: avoid_classes_with_only_static_members
class HttpCacheManager {
  static const key = 'pub_api_client_cache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(hours: 24),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

class CacheHttpClient extends http.BaseClient {
  final _inner = http.Client();

  CacheHttpClient();

  @override
  // ignore: type_annotate_public_apis
  Future<http.Response> get(url, {Map<String, String> headers}) async {
    final file =
        await HttpCacheManager.instance.getSingleFile(url, headers: headers);
    if (file != null && await file.exists()) {
      var res = await file.readAsString();
      return http.Response(res, 200);
    }
    return http.Response(null, 404);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }
}
