import 'package:fvm/exceptions.dart';

import 'package:fvm/src/flutter_tools/flutter_tools.dart';
import 'package:fvm/src/utils/logger.dart';

Future<void> flutterSetupWorkflow(String version) async {
  try {
    await runFlutterCmd(version, ['--version']);
  } on Exception catch (err) {
    logger.trace(err.toString());
    throw const InternalError('Could not finish setting up Flutter sdk');
  }
}
