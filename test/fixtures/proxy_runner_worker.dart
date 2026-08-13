import 'dart:io';

import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/fvm_release_service.dart';
import 'package:fvm/src/utils/constants.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:pub_semver/pub_semver.dart';

Future<void> main(List<String> arguments) async {
  final environment = Platform.environment;
  final context = FvmContext.create(
    appConfigPath: environment['FVM_TEST_APP_CONFIG']!,
    workingDirectoryOverride: environment['FVM_TEST_WORKSPACE']!,
  );
  final runner = FvmCommandRunner(
    context,
    releaseService: _MarkerReleaseService(
      context,
      markerPath: environment['FVM_TEST_RELEASE_MARKER']!,
    ),
  );

  exitCode = await runner.run(arguments);
}

class _MarkerReleaseService extends FvmReleaseService {
  final String markerPath;

  _MarkerReleaseService(super.context, {required this.markerPath});

  @override
  Future<FvmRelease> getLatestStableRelease() async {
    File(markerPath).writeAsStringSync('requested');

    return FvmRelease(
      version: Version(999, 0, 0),
      url: Uri.parse('$kFvmRepositoryUrl/releases/tag/999.0.0'),
    );
  }
}
