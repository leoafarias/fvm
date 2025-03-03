import '../models/cache_flutter_version_model.dart';
import 'workflow.dart';

class SetupFlutterWorkflow extends Workflow {
  SetupFlutterWorkflow(super.context);

  Future<void> call(CacheFlutterVersion version) async {
    // Skip setup if version has already been setup.
    if (version.isSetup) return;

    logger
      ..info('Setting up Flutter SDK: ${version.name}')
      ..lineBreak();

    try {
      await services.flutter
          .runFlutter(version, ['--version'], throwOnError: true);

      logger
        ..lineBreak()
        ..success('Flutter SDK: ${version.printFriendlyName} is setup');
    } on Exception catch (_) {
      logger.err('Failed to setup Flutter SDK');

      rethrow;
    }
  }
}
