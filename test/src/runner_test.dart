import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/commands/api_command.dart';
import 'package:fvm/src/runner.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late TestCommandRunner runner;

  setUp(() {
    runner = TestFactory.fastCommandRunner();
  });

  test('API commands preserve explicit non-zero exit codes', () async {
    final apiCommand = runner.commands['api'] as APICommand;
    apiCommand.addSubcommand(_ExitCommand(42));

    final result = await runner.run(['fvm', 'api', _ExitCommand.commandName]);

    expect(result, 42);
  });

  test('update check does not overwrite malformed configuration', () async {
    const malformedConfig = '{"lastUpdateCheck":';
    final tempDir = createTempDir('runner-config');
    final configFile = File(p.join(tempDir.path, 'config.json'));
    final context = FvmContext.create(
      appConfigPath: configFile.path,
      configOverrides: AppConfig(lastUpdateCheck: DateTime(2000)),
      workingDirectoryOverride: tempDir.path,
      isTest: true,
    );
    configFile.writeAsStringSync(malformedConfig);
    final updater = _TrackingPubUpdater();

    final result = await FvmCommandRunner(
      context,
      pubUpdater: updater,
    ).run(['--version']);

    expect(result, ExitCode.success.code);
    expect(configFile.readAsStringSync(), malformedConfig);
    expect(updater.calls, 0);
  });

  group('TestCommandRunner.runOrThrow', () {
    test('throws when a command returns a non-zero exit code', () async {
      runner.addCommand(_ExitCommand(42));

      expect(
        () => runner.runOrThrow(['fvm', _ExitCommand.commandName]),
        throwsA(isA<ProcessException>().having(
          (error) => error.errorCode,
          'errorCode',
          42,
        )),
      );
    });

    test('requires commands to start with the fvm executable', () async {
      expect(
        () => runner.runOrThrow(['other', '--version']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

class _ExitCommand extends Command<int> {
  static const commandName = 'exit-with-code';

  final int code;

  _ExitCommand(this.code);

  @override
  String get description => 'Returns a configured exit code for testing';

  @override
  String get name => commandName;

  @override
  int run() => code;
}

class _TrackingPubUpdater extends PubUpdater {
  int calls = 0;

  @override
  Future<bool> isUpToDate({
    required String packageName,
    required String currentVersion,
  }) async {
    calls++;
    return true;
  }
}
