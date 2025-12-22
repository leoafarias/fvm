import '../models/cache_flutter_version_model.dart';
import '../services/flutter_service.dart';
import 'workflow.dart';

class SetupFlutterWorkflow extends Workflow {
  const SetupFlutterWorkflow(super.context);

  Future<void> call(CacheFlutterVersion version) async {
    // Skip setup if version has already been setup.
    if (version.isSetup) return;

    logger
      ..info('Setting up Flutter SDK: ${version.name}')
      ..info();

    try {
      await get<FlutterService>().setup(version);
      logger
        ..info()
        ..success('Flutter SDK: ${version.printFriendlyName} is setup');
    } on Exception catch (e) {
      logger.err('Failed to setup Flutter SDK: $e');

      rethrow;
    }
  }
}
