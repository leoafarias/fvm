import 'package:fvm/src/commands/tui_command.dart';
import 'package:fvm/src/runner.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  test('rejects non-interactive contexts with unavailable', () async {
    final context = TestFactory.fastContext(skipInput: true);

    final result = await FvmCommandRunner(context).run(['tui']);

    expect(result, ExitCode.unavailable.code);
  });

  test('returns the injected launcher result unchanged', () async {
    final context = TestFactory.fastContext(stdinHasTerminal: true);
    var launches = 0;
    final command = TuiCommand(
      context,
      launcher: (launchedContext) async {
        launches += 1;
        expect(launchedContext, same(context));

        return 42;
      },
    );

    final result = await command.run();

    expect(result, 42);
    expect(launches, 1);
  });
}
