import 'package:io/ansi.dart';
import 'package:pub_api_client/pub_api_client.dart';

import '../version.dart';

/// Checks if there is an update for [currentVersion]
/// If not provided defaults to [packageVersion]
Future<bool> checkIfLatestVersion({String currentVersion}) async {
  currentVersion ??= packageVersion;
  try {
    final client = PubClient();

    final latest =
        await client.checkLatest('fvm', currentVersion: currentVersion);

    if (latest.needUpdate) {
      final updateCmd = cyan.wrap('pub global activate fvm');

      print(_divider);
      print(
          '''FVM Update Available $packageVersion → ${green.wrap(latest.latestVersion)} ''');
      print('${yellow.wrap('Changelog:')} ${latest.packageInfo.changelogUrl}');
      print('Run $updateCmd to update');
      print(_divider);
      return false;
    }
    return true;
  } on Exception {
    // Don't do anything fail silently
    return true;
  }
}

String get _divider {
  return yellow
      .wrap('\n___________________________________________________\n\n');
}
