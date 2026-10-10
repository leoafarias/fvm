import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// Pins the POSIX inherited-stdio launch contract. With FVM_FORWARD_SIGTERM the
// executable is resolved through the supplied PATH without an intermediary
// shell and a missing executable surfaces as a ProcessException. Without it
// the shell launch is preserved and a missing executable exits 127. The test
// context bypasses this path, so a production context with isTest: false is
// required.
void main() {
  late Directory directory;

  FvmContext createContext({required bool forwardSigterm}) {
    return FvmContext.create(
      configOverrides: AppConfig(
        cachePath: p.join(directory.path, 'cache'),
        gitCachePath: p.join(directory.path, 'cache.git'),
        useGitCache: false,
        privilegedAccess: false,
        disableUpdateCheck: true,
      ),
      appConfigPath: p.join(directory.path, 'config.json'),
      environmentOverrides: {'FVM_FORWARD_SIGTERM': '$forwardSigterm'},
      stdinHasTerminal: false,
      isTest: false,
    );
  }

  Future<ProcessResult> runMissing(FvmContext context) {
    return context.get<ProcessService>().run(
          'fvm_missing_executable_probe',
          environment: {
            ...Platform.environment,
            'PATH': p.join(directory.path, 'empty-bin'),
          },
          echoOutput: true,
          throwOnError: false,
        );
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fvm_posix_launch_');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'forwarding launches directly through the supplied PATH with verbatim args',
    () async {
      final binDir = Directory(p.join(directory.path, 'bin'))..createSync();
      final argsFile = File(p.join(directory.path, 'args'));
      final script = File(p.join(binDir.path, 'fvm_launch_probe'));
      script.writeAsStringSync(
        '#!/bin/sh\n'
        'for arg in "\$@"; do printf "%s\\n" "\$arg"; done > "${argsFile.path}"\n',
      );
      await Process.run('chmod', ['+x', script.path]);

      final result =
          await createContext(forwardSigterm: true).get<ProcessService>().run(
                'fvm_launch_probe',
                args: [r'$HOME', 'a b', '"quoted"', '*'],
                environment: {
                  ...Platform.environment,
                  'PATH':
                      '${binDir.path}:${Platform.environment['PATH'] ?? ''}',
                },
                echoOutput: true,
                throwOnError: false,
              );

      expect(result.exitCode, 0);
      expect(argsFile.readAsLinesSync(), [r'$HOME', 'a b', '"quoted"', '*']);
    },
    skip: Platform.isWindows ? 'POSIX launch contract' : false,
  );

  test(
    'forwarding surfaces a missing executable as ProcessException',
    () async {
      await expectLater(
        runMissing(createContext(forwardSigterm: true)),
        throwsA(isA<ProcessException>()),
      );
    },
    skip: Platform.isWindows ? 'POSIX launch contract' : false,
  );

  test(
    'default shell launch reports a missing executable as exit 127',
    () async {
      final result = await runMissing(createContext(forwardSigterm: false));

      expect(result.exitCode, 127);
    },
    skip: Platform.isWindows ? 'POSIX launch contract' : false,
  );
}
