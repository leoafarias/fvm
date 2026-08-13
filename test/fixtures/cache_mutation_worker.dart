import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:path/path.dart' as path;

final class _ControllableFlutterService extends FlutterService {
  const _ControllableFlutterService(
    super.context, {
    required this.signalPath,
    required this.delay,
    required this.fail,
    this.releasePath,
  });

  final String signalPath;
  final Duration delay;
  final bool fail;
  final String? releasePath;

  @override
  Future<void> install(
    FlutterVersion version, {
    bool useGitCache = true,
  }) async {
    final signal = File(signalPath);
    signal.parent.createSync(recursive: true);
    signal.writeAsStringSync('ready');

    if (releasePath case final releasePath?) {
      final releaseFile = File(releasePath);
      while (!releaseFile.existsSync()) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    } else {
      await Future<void>.delayed(delay);
    }
    if (fail) {
      throw const AppException('Intentional cache mutation worker failure.');
    }

    await super.install(version, useGitCache: useGitCache);
  }
}

Future<void> main(List<String> args) async {
  if (args.length != 6) {
    stderr.writeln(
      'Usage: cache_mutation_worker.dart '
      '<fvm-dir> <git-cache> <remote-url> <version> <signal> '
      '<delay-ms|wait:path|fail-wait:path>',
    );
    exitCode = 64;

    return;
  }

  final fvmDir = args[0];
  final gitCachePath = args[1];
  final flutterUrl = args[2];
  final version = FlutterVersion.parse(args[3]);
  final signalPath = args[4];
  final control = args[5];
  final shouldFail = control.startsWith('fail-wait:');
  final releasePath = switch (control) {
    final value when value.startsWith('wait:') =>
      value.substring('wait:'.length),
    final value when value.startsWith('fail-wait:') =>
      value.substring('fail-wait:'.length),
    _ => null,
  };
  final delayMilliseconds = releasePath == null ? int.parse(control) : 0;
  final delay = Duration(milliseconds: delayMilliseconds);

  final context = FvmContext.create(
    isTest: true,
    workingDirectoryOverride: path.dirname(fvmDir),
    appConfigPath: path.join(fvmDir, '.worker-config'),
    configOverrides: AppConfig(
      cachePath: fvmDir,
      gitCachePath: gitCachePath,
      flutterUrl: flutterUrl,
      useGitCache: false,
      disableUpdateCheck: true,
    ),
    generatorsOverride: {
      FlutterService: (context) => _ControllableFlutterService(
            context,
            signalPath: signalPath,
            delay: delay,
            fail: shouldFail,
            releasePath: releasePath,
          ),
    },
  );

  try {
    File('$signalPath.started')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('started');
    await EnsureCacheWorkflow(context).call(version, shouldInstall: true);
    stdout.writeln('installed');
  } on Exception catch (error, stackTrace) {
    stderr
      ..writeln(error)
      ..writeln(stackTrace);
    exitCode = 42;
  }
}
