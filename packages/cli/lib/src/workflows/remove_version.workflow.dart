import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/logger.dart';

Future<void> removeWorkflow(String version) async {
  FvmLogger.fine('Removing $version');
  try {
    await LocalVersionRepo.remove(version);
  } on Exception {
    throw InternalError('Could not remove $version');
  }
}
