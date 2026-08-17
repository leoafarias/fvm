import '../../services/logger_service.dart';
import '../../services/project_service.dart';
import '../../services/releases_service/releases_client.dart';
import '../../utils/context.dart';
import '../../utils/exceptions.dart';
import '../../workflows/ensure_cache.workflow.dart';
import '../../workflows/use_version.workflow.dart';
import '../../workflows/validate_flutter_version.workflow.dart';
import '../fvm_tui_models.dart';
import '../fvm_tui_ports.dart';
import 'fvm_context_handle.dart';

typedef TuiOperationContextFactory = FvmContext Function(FvmContext source);

final class ContextUseVersionRunner implements UseVersionRunner {
  final FvmContextHandle contextHandle;
  final TuiOperationContextFactory operationContextFactory;

  const ContextUseVersionRunner(
    this.contextHandle, {
    this.operationContextFactory = createTuiOperationContext,
  });

  @override
  Future<void> run(
    UseVersionRequest request,
    void Function(String) onEvent,
  ) async {
    final operationContext = operationContextFactory(contextHandle.current);
    final logger = operationContext.get<Logger>();
    await logger.runWithSink(_CallbackLogSink(onEvent), () async {
      final project = operationContext.get<ProjectService>().findAncestor();
      var requestedVersion = request.version;
      if (request.pin) {
        if (!const {'stable', 'beta', 'dev'}.contains(requestedVersion)) {
          throw const AppException(
            'Only stable, beta, and dev channels can be pinned.',
          );
        }
        requestedVersion =
            (await operationContext
                    .get<FlutterReleaseClient>()
                    .getLatestChannelRelease(requestedVersion))
                .version;
        logger.info('Pinning channel to Flutter $requestedVersion');
      }
      final version = operationContext.get<ValidateFlutterVersionWorkflow>()(
        requestedVersion,
      );
      final cacheVersion = await operationContext.get<EnsureCacheWorkflow>()(
        version,
        force: request.force,
      );
      await operationContext.get<UseVersionWorkflow>()(
        version: cacheVersion,
        project: project,
        force: request.force,
        skipSetup: false,
        skipPubGet: !request.runPubGet,
        flavor: request.flavor,
        updateVscodeSettings: request.updateVscode,
        updateMelosSettings: request.updateMelos,
        configureMissingMelos: request.updateMelos,
        updateExistingMelos: request.updateMelos,
      );
    });
  }
}

FvmContext createTuiOperationContext(FvmContext source) => FvmContext.create(
  debugLabel: source.debugLabel,
  workingDirectoryOverride: source.workingDirectory,
  environmentOverrides: source.environment,
  appConfigPath: source.appConfigPath,
  skipInput: true,
  stdinHasTerminal: source.stdinHasTerminal,
  logLevel: source.logLevel,
  isTest: source.isTest,
);

final class _CallbackLogSink implements LogSink {
  final void Function(String) onEvent;

  const _CallbackLogSink(this.onEvent);

  @override
  void add(LogEvent event) => onEvent(event.message);

  @override
  LogProgress startProgress(String message) {
    onEvent(message);

    return _CallbackLogProgress(onEvent);
  }
}

final class _CallbackLogProgress implements LogProgress {
  final void Function(String) onEvent;

  const _CallbackLogProgress(this.onEvent);

  @override
  void cancel([String? message]) => onEvent(message ?? 'Cancelled');

  @override
  void complete([String? message]) => onEvent(message ?? 'Complete');

  @override
  void fail([String? message]) => onEvent(message ?? 'Failed');
}
