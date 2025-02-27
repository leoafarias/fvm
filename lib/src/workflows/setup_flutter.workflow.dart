import '../models/cache_flutter_version_model.dart';
import '../utils/context.dart';

Future<void> setupFlutterWorkflow(
  CacheFlutterVersion version, {
  required FvmController controller,
}) async {
  controller.logger
    ..info('Setting up Flutter SDK: ${version.name}')
    ..spacer;

  await controller.flutterService.runFlutter(
    ['--version'],
    version: version,
    echoOutput: true,
  );

  controller.logger
    ..spacer
    ..success('Flutter SDK: ${version.printFriendlyName} is setup');
}
