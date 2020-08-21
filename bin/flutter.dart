import 'package:fvm/constants.dart';
import 'package:fvm/flutter/flutter_tools.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:fvm/utils/print.dart';
import 'package:fvm/utils/project_config.dart';
import 'package:process_run/which.dart';

Future<void> main(List<String> arguments) async {
  var flutterExec = getFlutterSdkExec();
  if (flutterExec == '') {
    final globalFlutter = await which('flutter');
    if (globalFlutter == '') {
      throw Exception('FVM: Flutter not found in path');
    }
    flutterExec = globalFlutter;
    PrettyPrint.info('FVM: Global Flutter\nPath: $flutterExec\n');
  } else {
    PrettyPrint.info(
        'FVM: Local Flutter ${getConfigFlutterVersion()}\nPath:($flutterExec)\n');
  }

  await flutterCmd(flutterExec, arguments,
      workingDirectory: kWorkingDirectory.path);
}
