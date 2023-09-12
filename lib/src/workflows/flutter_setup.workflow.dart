import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/logger.dart';

Future<void> setupFlutterWorkflow({
  required CacheFlutterVersion version,
}) async {
  // Skip if its test
  if (!version.notSetup || ctx.isTest) return;

  logger
    ..info('Setting up Flutter SDK: ${version.name}')
    ..spacer;

  await FlutterTools.instance.runSetup(version);
}

Future<void> resolveDependenciesWorkflow({
  required CacheFlutterVersion version,
  required Project project,
}) async {
  logDetails(version, project);

  if (project.dartToolVersion == version.flutterSdkVersion) {
    return;
  }

  final progress = logger.progress('Resolving dependencies...');

  try {
    await FlutterTools.instance.runPubGet(version);

    progress.complete('Dependencies resolved.');

    // Skip resolve if in vscode
  } on Exception catch (err) {
    if (project.dartToolVersion == version.flutterSdkVersion) {
      progress.complete('Dependencies resolved, with errors.');

      logger
        ..spacer
        ..warn(err.toString());

      return;
    } else {
      progress.fail('Could not resolve dependencies.');
      rethrow;
    }
  }
}

void logDetails(CacheFlutterVersion version, Project project) {
  final dartGeneratorVersion = project.dartToolGeneratorVersion;
  final dartToolVersion = project.dartToolVersion;
  final dartSdkVersion = version.dartSdkVersion;
  final flutterSdkVersion = version.flutterSdkVersion;
  // Print a separator line for easier reading
  logger.detail('----------------------------------------');

  // Print general information
  logger.detail('🔍  Verbose Details');
  logger.detail('');

  // Dart Information
  logger.detail('🎯 Dart Info:');
  logger.detail('   Dart Generator Version: $dartGeneratorVersion');
  logger.detail('   Dart SDK Version:       $dartSdkVersion');

  // Tool Information
  logger.detail('');
  logger.detail('🛠️ Tool Info:');
  logger.detail('   Dart Tool Version:      $dartToolVersion');
  logger.detail('   SDK Version:            $flutterSdkVersion');

  // Print another separator line for clarity
  logger.detail('----------------------------------------');

  if (dartToolVersion == flutterSdkVersion) {
    logger.detail('✅ Dart tool version matches SDK version, skipping resolve.');
    return;
  }

  // Print a warning for mismatch
  logger.detail('');
  logger.detail('⚠️ SDK version mismatch:');
  logger.detail('   Dart Tool Version:      $dartToolVersion');
  logger.detail('   Flutter SDK Version:    $flutterSdkVersion');
  logger.detail('');

  // Final separator line
  logger.detail('----------------------------------------');
}
