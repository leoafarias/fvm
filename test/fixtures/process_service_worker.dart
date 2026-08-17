import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  switch (args.first) {
    case 'arguments':
      stdout.writeln(jsonEncode(args.skip(1).toList()));
    case 'failure':
      stderr.writeln('stderr');
      exitCode = 23;
    case 'environment':
      stdout.writeln(Platform.environment['TEST_VAR']);
    case 'streaming':
      stdout.writeln('stdout-1');
      await stdout.flush();
      stderr.writeln('stderr-1');
      await stderr.flush();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      stdout.writeln('stdout-2');
      await stdout.flush();
      stderr.writeln('stderr-2');
      await stderr.flush();
    case 'wait-for-cancel':
      stdout.writeln('ready');
      await stdout.flush();
      await Completer<void>().future;
  }
}
