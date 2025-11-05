import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:fvm_mcp/src/process_runner.dart';
import 'package:test/test.dart';

void main() {
  const script = 'test/bin/fake_fvm.dart';

  ProcessRunner runner({required bool hasSkipInput}) => ProcessRunner(
        exe: Platform.resolvedExecutable,
        hasSkipInput: hasSkipInput,
        startMode: ProcessStartMode.normal,
      );

  String textFrom(CallToolResult result) {
    final contents = result.content.whereType<TextContent>();
    return contents.map((c) => c.text).join('\n');
  }

  test('run returns stdout text', () async {
    final res = await runner(hasSkipInput: false).run([
      script,
      'echo',
      'hello',
      'world',
    ]);

    expect(res.isError, anyOf(isNull, isFalse));
    expect(textFrom(res), 'hello world');
  });

  test('run appends --fvm-skip-input when supported', () async {
    final res = await runner(hasSkipInput: true).run([
      script,
      'echo_args_json',
      'alpha',
    ]);

    expect(res.isError, anyOf(isNull, isFalse));
    final args = jsonDecode(textFrom(res)) as List<dynamic>;
    expect(args.last, '--fvm-skip-input');
  });

  test('non-zero exit surfaces stderr', () async {
    final res = await runner(hasSkipInput: false).run([
      script,
      'stderr',
      'boom',
    ]);

    expect(res.isError, isTrue);
    expect(textFrom(res), contains('boom'));
  });

  test('timeout produces structured error', () async {
    final res = await runner(hasSkipInput: false).run(
      [
        script,
        'sleep',
        '2',
      ],
      timeout: const Duration(milliseconds: 100),
      progressLabel: 'sleep',
    );

    expect(res.isError, isTrue);
    expect(textFrom(res), contains('Timeout after 0m'));
  });
}
