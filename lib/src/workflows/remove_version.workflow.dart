import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/utils/pretty_print.dart';

Future<void> removeVersionWorkflow(String version) async {
  PrettyPrint.success('Removing $version');
  try {
    await LocalVersionRepo.remove(version);
  } on Exception {
    throw InternalError('Could not remove $version');
  }
}
