import 'package:dio/dio.dart';
import 'package:fvm/constants.dart';
// import 'package:path/path.dart' as path;

Future<void> fetchReleases() async {
  try {
    final response = await Dio().get(kFlutterReleasesListUrl);
    print(response);
  } catch (e) {
    print(e);
  }
}

Future<void> downloadVersion(String version) async {
  // final url = '$kFlutterReleasesUrl/$releasePath';
  // final versionPath = path.join(kVersionsDir.path, version)
  // final response = await Dio().download(url,kVersionsDir.path);

  // return response;
}
