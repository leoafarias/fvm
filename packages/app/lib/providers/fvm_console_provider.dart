import 'dart:convert';

import 'package:async/async.dart';
import 'package:fvm/fvm.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum OutputType {
  stderr,
  stdout,
}

class ConsoleLine {
  final OutputType type;
  final String text;
  ConsoleLine({this.type, this.text});
}

final combinedConsoleProvider = StreamProvider.autoDispose((ref) {
  return StreamGroup.merge([
    FVM.console.stdout.stream,
    FVM.console.stderr.stream,
    FVM.console.warning.stream,
    FVM.console.info.stream,
    FVM.console.fine.stream,
    FVM.console.error.stream,
  ])
      .transform(utf8.decoder)
      // .transform(const LineSplitter())
      .asBroadcastStream();
});
