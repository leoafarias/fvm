import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  switch (args.first) {
    case 'arguments':
      stdout.writeln(jsonEncode(args.skip(1).toList()));
    case 'failure':
      stderr.writeln('stderr');
      exitCode = 23;
    case 'environment':
      stdout.writeln(Platform.environment['TEST_VAR']);
  }
}
