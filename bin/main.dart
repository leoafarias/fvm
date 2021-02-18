import 'dart:io';

import 'package:fvm/fvm.dart';

Future<void> main(List<String> arguments) async {
  await fvmRunner(arguments);
  exit(exitCode);
}
