import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Fake FVM CLI used in tests to exercise [ProcessRunner].
Future<void> main(List<String> args) async {
  if (args.length == 1 && args.single == '--version') {
    stdout.write(Platform.environment['FAKE_FVM_VERSION'] ?? '4.1.2');
    exit(0);
  }

  final hadSkipInput = args.isNotEmpty && args.first == '--fvm-skip-input';
  if (hadSkipInput) args = args.skip(1).toList();
  if (args.isEmpty) {
    stderr.writeln('expected mode argument');
    exit(2);
  }

  final mode = args.first;
  final rest = args.skip(1).toList();

  switch (mode) {
    case 'echo':
      stdout.write(rest.join(' '));
      exit(0);
    case 'echo_args_json':
      stdout.write(jsonEncode({'hadSkipInput': hadSkipInput, 'args': rest}));
      exit(0);
    case 'api':
    case 'flutter':
      stdout.write(
        jsonEncode({
          'hadSkipInput': hadSkipInput,
          'args': [mode, ...rest],
        }),
      );
      exit(0);
    case 'stderr':
      stderr.write(rest.isEmpty ? 'error' : rest.join(' '));
      exit(1);
    case 'exit':
      final code = rest.isEmpty ? 1 : int.parse(rest.first);
      exit(code);
    case 'sleep':
      final seconds = rest.isEmpty ? 1 : int.parse(rest.first);
      await Future<void>.delayed(Duration(seconds: seconds));
      stdout.write('awake');
      exit(0);
    default:
      stderr.writeln('unknown mode: $mode');
      exit(3);
  }
}
