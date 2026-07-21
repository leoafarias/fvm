import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/commands/api_command.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/fvm_release_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/version.dart';
import 'package:io/io.dart';
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
}) {
  final context = _updateContext(
    disableUpdateCheck: disableUpdateCheck,
    lastUpdateCheck: lastUpdateCheck,
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
    isTest: true,
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
