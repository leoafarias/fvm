import '../models/cache_flutter_version_model.dart';
import '../utils/context.dart';

Future<void> setupFlutterWorkflow(CacheFlutterVersion version) async {
  ctx.loggerService
    ..info('Setting up Flutter SDK: ${version.name}')
    ..spacer;

  await version.run('--version', echoOutput: true);

  ctx.loggerService
    ..spacer
    ..success('Flutter SDK: ${version.printFriendlyName} is setup');
}
