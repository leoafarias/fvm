import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/services/logger_service.dart';

Future<void> setupFlutterWorkflow(CacheFlutterVersion version) async {
  logger
    ..info('Setting up Flutter SDK: ${version.name}')
    ..spacer;

  await version.run('--version', echoOutput: true);

  logger
    ..spacer
    ..success('Flutter SDK: ${version.printFriendlyName} is setup');
}
