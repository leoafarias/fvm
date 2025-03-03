import '../models/cache_flutter_version_model.dart';
import 'workflow.dart';

class SetupFlutterWorkflow extends Workflow {
  SetupFlutterWorkflow(super.context);

  Future<void> call(CacheFlutterVersion version) async {
    logger
      ..info('Setting up Flutter SDK: ${version.name}')
      ..lineBreak();

    await services.flutter.runFlutter(version, ['--version']);

    logger
      ..lineBreak()
      ..success('Flutter SDK: ${version.printFriendlyName} is setup');
  }
}
