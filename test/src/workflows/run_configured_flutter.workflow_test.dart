import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:fvm/src/workflows/run_configured_flutter.workflow.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

class _RecordingProcessService extends ProcessService {
  _RecordingProcessService(super.context);

  String? lastCommand;
  List<String>? lastArgs;
  Map<String, String>? lastEnvironment;

  @override
  Future<ProcessResult> run(
    String command, {
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool echoOutput = false,
    bool runInShell = true,
  }) async {
    lastCommand = command;
    lastArgs = args;
    lastEnvironment = environment;

    return ProcessResult(0, 0, '', '');
  }
}

Future<CacheFlutterVersion> _seedGlobalVersion(
  FvmContext context,
  FlutterVersion version,
) async {
  final flutterService = context.get<FlutterService>() as MockFlutterService;
  await flutterService.install(version, useArchive: true);

  final cacheService = context.get<CacheService>();
  final cacheVersion = cacheService.getVersion(version)!;
  cacheService.setGlobal(cacheVersion);

  return cacheVersion;
}

void main() {
  group('RunConfiguredFlutterWorkflow', () {
    test('runs cached global sdk without validating flutter url', () async {
      final cacheDir = createTempDir();
      final workingDir = createTempDir('run-configured-workflow');
      addTearDown(() {
        if (cacheDir.existsSync()) {
          cacheDir.deleteSync(recursive: true);
        }
        if (workingDir.existsSync()) {
          workingDir.deleteSync(recursive: true);
        }
      });

      late _RecordingProcessService processService;
      final context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: cacheDir.path,
          gitCachePath: p.join(cacheDir.path, 'gitcache'),
          flutterUrl: 'not a url',
          useGitCache: true,
        ),
        workingDirectoryOverride: workingDir.path,
        generatorsOverride: {
          FlutterService: (ctx) => MockFlutterService(ctx),
          ProcessService: (ctx) =>
              processService = _RecordingProcessService(ctx),
        },
      );

      final version = FlutterVersion.parse('stable');
      final cacheVersion = await _seedGlobalVersion(context, version);

      final workflow = RunConfiguredFlutterWorkflow(context);
      final result = await workflow.call('dart', args: ['--version']);

      expect(result.exitCode, equals(0));
      expect(processService.lastCommand, equals('dart'));
      expect(processService.lastArgs, equals(['--version']));
      expect(processService.lastEnvironment?['PATH'],
          contains(cacheVersion.binPath));
    });
  });

  group('EnsureCacheWorkflow', () {
    test('still validates flutter url when install is required', () async {
      final cacheDir = createTempDir();
      final workingDir = createTempDir('ensure-cache-workflow');
      addTearDown(() {
        if (cacheDir.existsSync()) {
          cacheDir.deleteSync(recursive: true);
        }
        if (workingDir.existsSync()) {
          workingDir.deleteSync(recursive: true);
        }
      });

      final context = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: cacheDir.path,
          gitCachePath: p.join(cacheDir.path, 'gitcache'),
          flutterUrl: 'not a url',
          useGitCache: true,
        ),
        workingDirectoryOverride: workingDir.path,
        generatorsOverride: {
          FlutterService: (ctx) => MockFlutterService(ctx),
        },
      );

      final workflow = EnsureCacheWorkflow(context);

      await expectLater(
        workflow.call(FlutterVersion.parse('stable')),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('Invalid Flutter URL'),
          ),
        ),
      );
    });
  });
}
