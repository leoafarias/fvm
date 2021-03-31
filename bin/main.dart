import 'dart:io';

import 'package:fvm/src/runner.dart';

void main(List<String> args) async {
  exit(await FvmCommandRunner().run(args));
}
