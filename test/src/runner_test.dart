import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/commands/api_command.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/fvm_release_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/version.dart';
import 'package:io/io.dart';
import 'package:mason_logger/mason_logger.dart' as mason;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
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

  for (final environment in <({String name, Map<String, String> values})>[
    (name: 'deprecated', values: const {'FVM_GIT_CACHE': 'deprecated'}),
    (name: 'legacy', values: const {'FVM_HOME': 'legacy'}),
  ]) {
    test(
      'does not pollute API JSON stdout with ${environment.name} environment diagnostics',
      () async {
        final result =
            await _runMachineOutputCommand('api', environment.values);

        expect(result.exitCode, ExitCode.success.code);
        expect(result.stdout, '{"result":"api"}\n');
        expect(result.stderr, isEmpty);
      },
    );

    test(
      'does not pollute completion stdout with ${environment.name} environment diagnostics',
      () async {
        final result = await _runMachineOutputCommand(
          'completion',
          environment.values,
        );

        expect(result.exitCode, ExitCode.success.code);
        expect(result.stdout, 'flutter\nflavor\n');
        expect(result.stderr, isEmpty);
      },
    );
  }

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
    final releaseService = _TrackingReleaseService(
      context,
      release: _release(_nextPatchVersion),
    );

    final result = await FvmCommandRunner(
      context,
      releaseService: releaseService,
    ).run(['--version']);

    expect(result, ExitCode.success.code);
    expect(configFile.readAsStringSync(), malformedConfig);
    expect(releaseService.calls, 0);
  });

  group('ForceExit handling', () {
    test('returns usage without logging an empty selector message', () async {
      late _InfoTrackingLogger logger;
      final context = TestFactory.fastContext(
        skipInput: true,
        generators: {
          Logger: (context) => logger = _InfoTrackingLogger(context),
        },
      );
      final runner = TestCommandRunner(context);
      FakeFlutterSdkFixture.install(
        context,
        FlutterVersion.parse('stable'),
      );

      final result = await runner.run(['fvm', 'remove']);

      expect(result, ExitCode.usage.code);
      expect(logger.infoMessages, isEmpty);
    });

    test('returns the code and logs a non-empty message', () async {
      late _InfoTrackingLogger logger;
      final context = TestFactory.fastContext(
        generators: {
          Logger: (context) => logger = _InfoTrackingLogger(context),
        },
      );
      final runner = FvmCommandRunner(context)
        ..addCommand(_ForceExitCommand('stop', 42));

      final result = await runner.run([_ForceExitCommand.commandName]);

      expect(result, 42);
      expect(logger.infoMessages, ['stop']);
    });
  });

  group('GitHub release update checks', () {
    test('checks on first run and records the attempt', () async {
      final fixture = _updateFixture(
        release: _release(_nextPatchVersion),
      );

      final result = await fixture.runner.run(['--version']);

      expect(result, ExitCode.success.code);
      expect(fixture.service.calls, 1);
      expect(
        LocalAppConfig.read(
          path: fixture.context.appConfigPath,
        ).lastUpdateCheck,
        isNotNull,
      );
      expect(
        fixture.context.get<Logger>().outputs.join('\n'),
        allOf(
          contains('Update available!'),
          contains(packageVersion),
          contains(_nextPatchVersion.toString()),
          contains(_release(_nextPatchVersion).url.toString()),
          isNot(contains(kFvmMigrationGuideUrl)),
        ),
      );
    });

    test('honors the update-check opt-out', () async {
      final fixture = _updateFixture(
        release: _release(_nextPatchVersion),
        disableUpdateCheck: true,
      );

      final result = await fixture.runner.run(['--version']);

      expect(result, ExitCode.success.code);
      expect(fixture.service.calls, 0);
      expect(
        LocalAppConfig.read(
          path: fixture.context.appConfigPath,
        ).lastUpdateCheck,
        isNull,
      );
    });

    test('does not check again within one day', () async {
      final recentCheck = DateTime.now().subtract(const Duration(hours: 1));
      final fixture = _updateFixture(
        release: _release(_nextPatchVersion),
        lastUpdateCheck: recentCheck,
      );

      final result = await fixture.runner.run(['--version']);

      expect(result, ExitCode.success.code);
      expect(fixture.service.calls, 0);
      final persistedCheck = LocalAppConfig.read(
        path: fixture.context.appConfigPath,
      ).lastUpdateCheck;
      expect(persistedCheck, isNotNull);
      expect(persistedCheck!.isAtSameMomentAs(recentCheck), isTrue);
    });

    test('checks again after one day', () async {
      final oldCheck = DateTime(2000);
      final fixture = _updateFixture(
        release: _release(_currentVersion),
        lastUpdateCheck: oldCheck,
      );

      final result = await fixture.runner.run(['--version']);

      expect(result, ExitCode.success.code);
      expect(fixture.service.calls, 1);
      final persistedCheck = LocalAppConfig.read(
        path: fixture.context.appConfigPath,
      ).lastUpdateCheck;
      expect(persistedCheck, isNotNull);
      expect(persistedCheck!.isAfter(oldCheck), isTrue);
    });

    test('prints standalone migration guidance for a newer major', () async {
      final nextMajor = Version(_currentVersion.major + 1, 0, 0);
      final fixture = _updateFixture(
        release: _release(nextMajor),
      );

      final result = await fixture.runner.run(['--version']);

      expect(result, ExitCode.success.code);
      expect(
        fixture.context.get<Logger>().outputs.join('\n'),
        allOf(
          contains('FVM ${nextMajor.major} is distributed as a standalone CLI'),
          contains('no longer published to pub.dev'),
          contains(kFvmMigrationGuideUrl),
        ),
      );
    });

    test('does not suggest an equal or older release', () async {
      for (final latestVersion in [_currentVersion, Version(0, 0, 0)]) {
        final fixture = _updateFixture(
          release: _release(latestVersion),
        );

        final result = await fixture.runner.run(['--version']);

        expect(result, ExitCode.success.code);
        expect(fixture.service.calls, 1);
        expect(
          fixture.context.get<Logger>().outputs.join('\n'),
          isNot(contains('Update available!')),
        );
      }
    });

    test('keeps release lookup failures debug-only', () async {
      final fixture = _updateFixture(
        failure: const FvmReleaseException('offline'),
      );

      final result = await fixture.runner.run(['--version']);

      expect(result, ExitCode.success.code);
      expect(fixture.service.calls, 1);
      expect(
        fixture.context.get<Logger>().outputs,
        contains('Failed to check for updates.'),
      );
    });

    test('preserves a command non-zero exit code', () async {
      final fixture = _updateFixture(
        release: _release(_nextPatchVersion),
      );
      fixture.runner.addCommand(_ExitCommand(42));

      final result = await fixture.runner.run([_ExitCommand.commandName]);

      expect(result, 42);
      expect(fixture.service.calls, 1);
    });

    test('does not check for API commands', () async {
      final fixture = _updateFixture(
        release: _release(_nextPatchVersion),
      );
      final apiCommand = fixture.runner.commands['api'] as APICommand;
      apiCommand.addSubcommand(_ExitCommand(42));

      final result = await fixture.runner.run([
        'api',
        _ExitCommand.commandName,
      ]);

      expect(result, 42);
      expect(fixture.service.calls, 0);
    });

    test(
      'treats top-level version before a proxy name as an FVM version request',
      () async {
        final fixture = _proxyUpdateFixture(
          environmentOverrides: const {'FVM_GIT_CACHE': 'deprecated'},
        );
        final flutterService =
            fixture.context.get<FlutterService>() as FakeFlutterService;

        final result = await fixture.runner.run(['--version', 'flutter']);

        expect(result, ExitCode.success.code);
        expect(fixture.service.calls, 1);
        expect(flutterService.runCalls, isEmpty);
        expect(
          fixture.context.get<Logger>().outputs,
          containsAll([
            packageVersion,
            'Deprecated environment variables detected:',
          ]),
        );
      },
    );

    for (final invocation in <List<String>>[
      ['flutter', '--version'],
      ['dart', '--version'],
      ['exec', 'flutter', '--version'],
      ['spawn', 'stable', '--version'],
    ]) {
      test('does not check for ${invocation.first} proxy commands', () async {
        final fixture = _proxyUpdateFixture();

        final result = await fixture.runner.run(invocation);

        expect(result, ExitCode.success.code);
        expect(fixture.service.calls, 0);
      });
    }

    for (final commandName in <String>[
      HandleCompletionRequestCommand.commandName,
      InstallCompletionFilesCommand.commandName,
      UnistallCompletionFilesCommand.commandName,
    ]) {
      test('does not check for $commandName completion commands', () async {
        final fixture = _updateFixture(
          release: _release(_nextPatchVersion),
        );
        final runner = _SafeCompletionRunner(
          fixture.context,
          fixture.service,
        );

        final result = await runner.run([commandName]);

        expect(result, ExitCode.success.code);
        expect(fixture.service.calls, 0);
      });
    }

    test('writes update notices to stderr instead of stdout', () async {
      final fixture = _updateFixture(
        release: _release(_nextPatchVersion),
        logLevel: Level.info,
      );
      final stdout = _MockStdout();
      final stderr = _MockStdout();
      when(() => stdout.supportsAnsiEscapes).thenReturn(false);
      when(() => stderr.supportsAnsiEscapes).thenReturn(false);

      final result = await IOOverrides.runZoned(
        () => fixture.runner.run(['--version']),
        stdout: () => stdout,
        stderr: () => stderr,
      );
      final stdoutLines = verify(
        () => stdout.writeln(captureAny<dynamic>()),
      ).captured.join('\n');
      final stderrLines = verify(
        () => stderr.writeln(captureAny<dynamic>()),
      ).captured.join('\n');

      expect(result, ExitCode.success.code);
      expect(stdoutLines, contains(packageVersion));
      expect(stdoutLines, isNot(contains('Update available!')));
      expect(stderrLines, contains('Update available!'));
      expect(stderrLines, contains(_release(_nextPatchVersion).url.toString()));
    });

    for (final diagnosticEnvironment
        in <({String name, Map<String, String> values})>[
      (name: 'deprecated', values: const {'FVM_GIT_CACHE': 'deprecated'}),
      (name: 'legacy', values: const {'FVM_HOME': 'legacy'}),
    ]) {
      for (final invocation in <List<String>>[
        ['flutter'],
        ['dart'],
        ['exec', 'flutter'],
        ['spawn', 'stable'],
      ]) {
        test(
          'preserves ${invocation.first} proxy stdout byte-for-byte with '
          '${diagnosticEnvironment.name} environment diagnostics',
          () async {
            const expectedOutput = 'proxy line one\nproxy final byte';
            final tempDir = createTempDir('runner-proxy-output');
            final workspace = Directory(p.join(tempDir.path, 'workspace'))
              ..createSync(recursive: true);
            final home = Directory(p.join(tempDir.path, 'home'))
              ..createSync(recursive: true);
            final cachePath = p.join(tempDir.path, 'cache');
            final flutterExecutable = File(
              p.join(
                cachePath,
                'versions',
                'stable',
                'bin',
                flutterExecFileName,
              ),
            )..createSync(recursive: true);
            final payloadScript =
                File(p.join(tempDir.path, 'proxy_payload.dart'))
                  ..writeAsStringSync(
                    "import 'dart:io';\n"
                    "void main() => stdout.write('proxy line one\\nproxy final byte');\n",
                  );
            flutterExecutable.writeAsStringSync(
              Platform.isWindows
                  ? '@echo off\r\n'
                      '"${Platform.resolvedExecutable}" "${payloadScript.path}"'
                  : '#!/bin/sh\n'
                      'exec "${Platform.resolvedExecutable}" "${payloadScript.path}"',
            );
            if (!Platform.isWindows) {
              final chmod =
                  await Process.run('chmod', ['+x', flutterExecutable.path]);
              expect(chmod.exitCode, ExitCode.success.code);
            }
            final dartExecutable = File(
              p.join(
                cachePath,
                'versions',
                'stable',
                'bin',
                dartExecFileName,
              ),
            )..createSync(recursive: true);
            dartExecutable.writeAsStringSync(
              Platform.isWindows
                  ? '@echo off\r\n'
                      '"${Platform.resolvedExecutable}" "${payloadScript.path}"'
                  : '#!/bin/sh\n'
                      'exec "${Platform.resolvedExecutable}" "${payloadScript.path}"',
            );
            if (!Platform.isWindows) {
              final chmod =
                  await Process.run('chmod', ['+x', dartExecutable.path]);
              expect(chmod.exitCode, ExitCode.success.code);
            }
            File(
              p.join(cachePath, 'versions', 'stable', 'version'),
            ).writeAsStringSync('3.10.5');
            createProjectConfig(
                const ProjectConfig(flutter: 'stable'), workspace);
            final releaseMarker =
                File(p.join(tempDir.path, 'release-requested'));
            final environment = Map<String, String>.from(Platform.environment)
              ..remove('FVM_GIT_CACHE')
              ..remove('FVM_HOME')
              ..remove('FVM_CACHE_PATH')
              ..['HOME'] = home.path
              ..['FVM_GIT_CACHE_PATH'] = p.join(tempDir.path, 'cache.git')
              ..['FVM_TEST_APP_CONFIG'] = p.join(tempDir.path, 'config.json')
              ..['FVM_TEST_WORKSPACE'] = workspace.path
              ..['FVM_TEST_RELEASE_MARKER'] = releaseMarker.path
              ..addAll(diagnosticEnvironment.values);
            if (diagnosticEnvironment.name == 'legacy') {
              environment['FVM_HOME'] = cachePath;
            } else {
              environment['FVM_CACHE_PATH'] = cachePath;
            }

            final result = await Process.run(
              Platform.resolvedExecutable,
              ['test/fixtures/proxy_runner_worker.dart', ...invocation],
              environment: environment,
              workingDirectory: Directory.current.path,
            );

            expect(result.exitCode, ExitCode.success.code);
            expect(result.stdout, expectedOutput);
            if (invocation.first == 'spawn') {
              expect(result.stderr, 'Spawning version "stable"...\n');
            } else {
              expect(result.stderr, isEmpty);
            }
            expect(releaseMarker.existsSync(), isFalse);
          },
        );
      }
    }
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

class _ForceExitCommand extends Command<int> {
  static const commandName = 'force-exit';

  final String message;
  final int code;

  _ForceExitCommand(this.message, this.code);

  @override
  String get description => 'Throws a ForceExit for testing';

  @override
  String get name => commandName;

  @override
  Never run() => throw ForceExit(message, code);
}

final _currentVersion = Version.parse(packageVersion);

final _nextPatchVersion = Version(
  _currentVersion.major,
  _currentVersion.minor,
  _currentVersion.patch + 1,
);

typedef _UpdateFixture = ({
  FvmContext context,
  _TrackingReleaseService service,
  FvmCommandRunner runner,
});

_UpdateFixture _updateFixture({
  FvmRelease? release,
  Object? failure,
  bool? disableUpdateCheck,
  DateTime? lastUpdateCheck,
  Level? logLevel,
}) {
  final context = _updateContext(
    disableUpdateCheck: disableUpdateCheck,
    lastUpdateCheck: lastUpdateCheck,
    logLevel: logLevel,
  );
  final service = _TrackingReleaseService(
    context,
    release: release,
    failure: failure,
  );

  return (
    context: context,
    service: service,
    runner: FvmCommandRunner(context, releaseService: service),
  );
}

FvmContext _updateContext({
  bool? disableUpdateCheck,
  DateTime? lastUpdateCheck,
  Level? logLevel,
}) {
  final tempDir = createTempDir('runner-update-check');
  final configFile = File(p.join(tempDir.path, 'config.json'));
  if (disableUpdateCheck != null || lastUpdateCheck != null) {
    LocalAppConfig(
      disableUpdateCheck: disableUpdateCheck,
      lastUpdateCheck: lastUpdateCheck,
    ).save(path: configFile.path);
  }

  return FvmContext.create(
    appConfigPath: configFile.path,
    workingDirectoryOverride: tempDir.path,
    logLevel: logLevel,
    isTest: true,
  );
}

_UpdateFixture _proxyUpdateFixture({
  Map<String, String>? environmentOverrides,
}) {
  final tempDir = createTempDir('runner-proxy-update-check');
  final workspace = Directory(p.join(tempDir.path, 'workspace'))
    ..createSync(recursive: true);
  final configFile = File(p.join(tempDir.path, 'config.json'));
  final context = FvmContext.create(
    configOverrides: AppConfig(
      cachePath: p.join(tempDir.path, 'cache'),
      gitCachePath: p.join(tempDir.path, 'cache.git'),
      disableUpdateCheck: false,
      useGitCache: true,
    ),
    appConfigPath: configFile.path,
    workingDirectoryOverride: workspace.path,
    environmentOverrides: environmentOverrides,
    generatorsOverride: {
      FlutterService: FakeFlutterService.new,
      FlutterReleaseClient: FakeFlutterReleaseClient.new,
      GitService: FakeGitService.new,
    },
    isTest: true,
  );
  createProjectConfig(const ProjectConfig(flutter: 'stable'), workspace);
  FakeFlutterSdkFixture.install(
    context,
    FlutterVersion.parse('stable'),
    state: FakeFlutterSdkState.installedSetup,
  );
  final service = _TrackingReleaseService(
    context,
    release: _release(_nextPatchVersion),
  );

  return (
    context: context,
    service: service,
    runner: FvmCommandRunner(context, releaseService: service),
  );
}

FvmRelease _release(Version version) {
  return FvmRelease(
    version: version,
    url: Uri.parse('$kFvmRepositoryUrl/releases/tag/$version'),
  );
}

class _TrackingReleaseService extends FvmReleaseService {
  int calls = 0;
  final FvmRelease? release;
  final Object? failure;

  _TrackingReleaseService(
    super.context, {
    this.release,
    this.failure,
  });

  @override
  Future<FvmRelease> getLatestStableRelease() async {
    calls++;
    final failure = this.failure;
    if (failure != null) throw failure;

    return release!;
  }
}

class _SafeCompletionRunner extends FvmCommandRunner {
  _SafeCompletionRunner(
    FvmContext context,
    FvmReleaseService releaseService,
  ) : super(context, releaseService: releaseService);

  @override
  void tryInstallCompletionFiles(mason.Level level, {bool force = false}) {}

  @override
  void tryUninstallCompletionFiles(mason.Level level) {}
}

class _MockStdout extends Mock implements Stdout {}

Future<ProcessResult> _runMachineOutputCommand(
  String command,
  Map<String, String> diagnosticsEnvironment,
) async {
  final tempDir = createTempDir('runner-machine-output');
  final environment = Map<String, String>.from(Platform.environment)
    ..remove('FVM_GIT_CACHE')
    ..remove('FVM_HOME')
    ..remove('FVM_CACHE_PATH')
    ..['HOME'] = tempDir.path
    ..['FVM_TEST_APP_CONFIG'] = p.join(tempDir.path, 'config.json')
    ..addAll(diagnosticsEnvironment);

  if (command == 'completion') {
    environment.addAll(const {
      'SHELL': '/bin/bash',
      'COMP_LINE': 'fvm fl',
      'COMP_POINT': '6',
      'COMP_CWORD': '1',
    });
  }

  return Process.run(
    Platform.resolvedExecutable,
    ['test/fixtures/runner_machine_output_worker.dart', command],
    environment: environment,
    workingDirectory: Directory.current.path,
  );
}

class _InfoTrackingLogger extends Logger {
  final infoMessages = <String>[];

  _InfoTrackingLogger(super.context);

  @override
  void info([String message = '']) {
    infoMessages.add(message);
  }
}
