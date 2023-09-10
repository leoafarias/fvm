import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:interact/interact.dart';

Future<FlutterVersion?> validateFlutterVersion(String version) async {
  final flutterVersion = FlutterVersion.fromString(version);
  if (flutterVersion.isChannel || flutterVersion.isCommit) {
    return flutterVersion;
  }

  final releases = await FlutterReleasesClient.get();

  final isVersion = releases.containsVersion(flutterVersion.version);

  if (!isVersion) {
    logger.notice('Version: ($version) is not valid Flutter version');

    final askConfirmation = Confirm(
      prompt: 'Do you want to continue?',
      defaultValue: false,
    );
    if (askConfirmation.interact()) {
      return flutterVersion;
    } else {
      return null;
    }
  }

  return flutterVersion;
}
