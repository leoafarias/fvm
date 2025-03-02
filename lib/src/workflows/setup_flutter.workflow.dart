import '../models/cache_flutter_version_model.dart';
import '../utils/context.dart';

Future<void> setupFlutterWorkflow(
  CacheFlutterVersion version, {
  required FVMContext context,
}) async {
  final services = context.services;
  final logger = context.logger;

  logger
    ..info('Setting up Flutter SDK: ${version.name}')
    ..lineBreak();

  await services.flutter.runFlutter(version, ['--version']);

  logger
    ..lineBreak()
    ..success('Flutter SDK: ${version.friendlyName} is setup');
}
