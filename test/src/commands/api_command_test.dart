import 'package:args/command_runner.dart';
import 'package:fvm/src/api/models/json_response.dart';
import 'package:fvm/src/commands/api_command.dart';
import 'package:test/test.dart';

class TestCommandRunner extends CommandRunner<int> {
  TestCommandRunner() : super('fvm', '');
}

final apiCommand = TestCommandRunner()..addCommand(ApiCommand());

void main() {
  group('ApiCommand test', () {
    test(
      'list',
      () async {
        // Expect to throw UsageException
        expect(() => apiCommand.run(['api', 'list']),
            throwsA(isA<ListCommandResponse>()));
      },
    );

    test(
      'releases',
      () async {
        // Expect to print releases
        expect(
          () => apiCommand.run(['api', 'releases']),
          throwsA(isA<ReleasesCommandResponse>()),
        );
      },
    );
  });
}
