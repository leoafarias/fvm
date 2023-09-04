import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/utils/logger.dart';

Future<void> setupFlutterWorkflow(CacheFlutterVersion version) async {
  if (!version.notSetup) return;

  logger
    ..info('Setting up Flutter SDK: ${version.name}')
    ..spacer;

  await FlutterTools.runSetup(version);
}
