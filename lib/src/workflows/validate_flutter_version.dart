import 'package:fvm/exceptions.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/logger.dart';

Future<FlutterVersion> validateFlutterVersion(String version) async {
  final flutterVersion = FlutterVersion.parse(version);
  // If its channel or commit no need for further validation
  if (flutterVersion.isChannel || flutterVersion.isCustom) {
    return flutterVersion;
  }

  if (flutterVersion.isRelease) {
    // Check version incase it as a releaseChannel i.e. 2.2.2@beta
    final isTag = await FlutterTools.instance.isTag(flutterVersion.version);

    if (isTag) {
      return flutterVersion;
    }
  }

  if (flutterVersion.isCommit) {
    final commitSha = await FlutterTools.instance.getReference(version);
    if (commitSha != null) {
      if (commitSha != flutterVersion.name) {
        throw AppException(
          'FVM only supports short commit SHAs (10 characters) should be ($commitSha)',
        );
      }
      return flutterVersion;
    }
  }

  logger.notice(
    'Flutter SDK: (version) is not valid Flutter version',
  );

  final askConfirmation = logger.confirm(
    'Do you want to continue?',
    defaultValue: false,
  );
  if (askConfirmation) {
    // Jump a line after confirmation
    logger.spacer;
    return flutterVersion;
  }

  throw AppException(
    '$version is not a valid Flutter version',
  );
}
