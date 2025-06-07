import 'package:fvm/fvm.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Command Aliases Test:', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    group('Install command aliases:', () {
      test('fvm i works same as fvm install', () async {
        const version = TestVersions.stable;

        // Test that 'fvm i' works
        final exitCode = await runner.runOrThrow(['fvm', 'i', version]);
        expect(exitCode, ExitCode.success.code);

        // Verify installation
        final cacheVersion = runner.context.get<CacheService>().getVersion(
              FlutterVersion.parse(version),
            );
        expect(cacheVersion != null, true, reason: 'Install via alias failed');
      });

      test('fvm i shows same help as fvm install', () async {
        // Both should show help and succeed
        final iResult = await runner.run(['fvm', 'i', '--help']);
        final installResult = await runner.run(['fvm', 'install', '--help']);

        expect(iResult, equals(installResult));
      });
    });

    group('List command aliases:', () {
      test('fvm ls works same as fvm list', () async {
        // Both commands should succeed
        final exitCodeAlias = await runner.runOrThrow(['fvm', 'ls']);
        final exitCodeFull = await runner.runOrThrow(['fvm', 'list']);

        expect(exitCodeAlias, ExitCode.success.code);
        expect(exitCodeFull, ExitCode.success.code);
      });

      test('fvm ls shows same help as fvm list', () async {
        // Both should show help and succeed
        final lsResult = await runner.run(['fvm', 'ls', '--help']);
        final listResult = await runner.run(['fvm', 'list', '--help']);

        expect(lsResult, equals(listResult));
      });
    });

    group('All command aliases verification:', () {
      test('All defined aliases are accessible', () async {
        final runner = TestFactory.commandRunner();

        // Test install alias
        expect(runner.commands.containsKey('i'), true);
        expect(runner.commands.containsKey('install'), true);
        expect(runner.commands['i']?.name, equals('install'));

        // Test list alias
        expect(runner.commands.containsKey('ls'), true);
        expect(runner.commands.containsKey('list'), true);
        expect(runner.commands['ls']?.name, equals('list'));
      });
    });
  });
}
