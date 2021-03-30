import 'dart:io';

import 'package:fvm/fvm.dart';

void main(List<String> args) async {
  exit(await FvmCommandRunner().run(args));
}
