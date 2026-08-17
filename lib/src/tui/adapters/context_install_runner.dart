import '../../models/cache_flutter_version_model.dart';
import '../../services/install_observer.dart';
import '../../services/logger_service.dart';
import '../../services/operation_cancellation.dart';
import '../../services/process_service.dart';
import '../../services/project_service.dart';
import '../../utils/context.dart';
import '../../workflows/ensure_cache.workflow.dart';
import '../../workflows/setup_flutter.workflow.dart';
import '../../workflows/use_version.workflow.dart';
import '../../workflows/validate_flutter_version.workflow.dart';
import '../fvm_tui_models.dart';
import '../fvm_tui_ports.dart';
import 'context_use_version_runner.dart';
import 'fvm_context_handle.dart';

final class ContextInstallRunner implements InstallRunner {
  final FvmContextHandle contextHandle;
  final TuiOperationContextFactory operationContextFactory;

  const ContextInstallRunner(
    this.contextHandle, {
    this.operationContextFactory = createTuiOperationContext,
  });

  static void _completeMissingCachePhases(
    void Function(
      InstallPhase phase,
      OperationStatus status,
      String detail, {
      int? exactPercent,
    })
    emit,
    Set<InstallPhase> completed,
  ) {
    final missingPhases = const [
      InstallPhase.acquireLock,
      InstallPhase.cloneSdk,
      InstallPhase.validateRevision,
    ].where((phase) => !completed.contains(phase));
    for (final phase in missingPhases) {
      emit(phase, OperationStatus.active, 'Already satisfied');
      emit(phase, OperationStatus.complete, 'Already satisfied');
    }
  }

  static Future<void> _linkProject(
    FvmContext operationContext,
    CacheFlutterVersion cacheVersion,
    bool force,
  ) async {
    final project = operationContext.get<ProjectService>().findAncestor();
    final projectConfig = project.config;
    final appConfig = operationContext.config;
    final runPubGet =
        projectConfig?.runPubGetOnSdkChanges ??
        appConfig.runPubGetOnSdkChanges ??
        true;
    final updateVscode =
        projectConfig?.updateVscodeSettings ??
        appConfig.updateVscodeSettings ??
        true;
    final updateMelos =
        projectConfig?.updateMelosSettings ??
        appConfig.updateMelosSettings ??
        true;

    await operationContext.get<UseVersionWorkflow>()(
      version: cacheVersion,
      project: project,
      force: force,
      skipSetup: true,
      skipPubGet: !runPubGet,
      updateVscodeSettings: updateVscode,
      updateMelosSettings: updateMelos,
      configureMissingMelos: updateMelos,
      updateExistingMelos: updateMelos,
    );
  }

  @override
  ProcessCancellation createCancellation() => ProcessCancellation();

  @override
  Future<void> run(
    InstallRequest request, {
    required void Function(InstallProgressUpdate) onProgress,
    required OperationCancellation cancellation,
  }) async {
    if (cancellation is! ProcessCancellation) {
      throw ArgumentError.value(
        cancellation,
        'cancellation',
        'ContextInstallRunner requires ProcessCancellation',
      );
    }

    final sourceContext = contextHandle.current;
    final operationContext = operationContextFactory(sourceContext);
    final completed = <InstallPhase>{};
    InstallPhase? activePhase;

    void emit(
      InstallPhase phase,
      OperationStatus status,
      String detail, {
      int? exactPercent,
    }) {
      assert(phase == InstallPhase.cloneSdk || exactPercent == null);
      switch (status) {
        case OperationStatus.active:
          activePhase = phase;
          break;
        case OperationStatus.complete:
          completed.add(phase);
          if (activePhase == phase) activePhase = null;
          break;
        case OperationStatus.pending ||
            OperationStatus.failed ||
            OperationStatus.cancelled:
          break;
      }
      onProgress((
        phase: phase,
        status: status,
        detail: detail,
        exactPercent: exactPercent,
      ));
    }

    for (final phase in InstallPhase.values) {
      emit(phase, OperationStatus.pending, 'Pending');
    }

    void completeEnsureCache() {
      if (completed.contains(InstallPhase.ensureCache)) return;
      emit(
        InstallPhase.ensureCache,
        OperationStatus.complete,
        'Cache preflight complete',
      );
    }

    final observer = CallbackInstallObserver((update) {
      completeEnsureCache();
      final phase = switch (update.phase) {
        InstallObservationPhase.acquireLock => InstallPhase.acquireLock,
        InstallObservationPhase.cloneSdk => InstallPhase.cloneSdk,
        InstallObservationPhase.validateRevision =>
          InstallPhase.validateRevision,
      };
      final status = switch (update.status) {
        InstallObservationStatus.active => OperationStatus.active,
        InstallObservationStatus.complete ||
        InstallObservationStatus.skipped => OperationStatus.complete,
      };
      emit(
        phase,
        status,
        update.detail,
        exactPercent: phase == InstallPhase.cloneSdk
            ? update.gitProgress?.percent
            : null,
      );
    });

    final logger = operationContext.get<Logger>();
    try {
      await logger.runWithSink(
        _InstallLogSink((message) {
          final phase = activePhase;
          if (phase != null) emit(phase, OperationStatus.active, message);
        }),
        () async {
          emit(
            InstallPhase.ensureCache,
            OperationStatus.active,
            'Preparing Flutter ${request.version}',
          );
          final version = operationContext
              .get<ValidateFlutterVersionWorkflow>()(request.version);
          final cacheVersion = await operationContext
              .get<EnsureCacheWorkflow>()
              .call(
                version,
                shouldInstall: true,
                force: request.force,
                useGitCache: request.useGitCache,
                observer: observer,
                cancellation: cancellation,
              );
          completeEnsureCache();
          _completeMissingCachePhases(emit, completed);

          if (request.runSetup) {
            emit(
              InstallPhase.setupFlutter,
              OperationStatus.active,
              'Setting up Flutter',
            );
            await operationContext.get<SetupFlutterWorkflow>()(cacheVersion);
            emit(
              InstallPhase.setupFlutter,
              OperationStatus.complete,
              'Flutter setup complete',
            );
          } else {
            emit(
              InstallPhase.setupFlutter,
              OperationStatus.complete,
              'Setup skipped',
            );
          }

          if (request.useAfterInstall) {
            emit(
              InstallPhase.linkProject,
              OperationStatus.active,
              'Linking project',
            );
            await _linkProject(operationContext, cacheVersion, request.force);
            emit(
              InstallPhase.linkProject,
              OperationStatus.complete,
              'Project linked',
            );
          } else {
            emit(
              InstallPhase.linkProject,
              OperationStatus.complete,
              'Project link skipped',
            );
          }
        },
      );
    } on OperationCanceledException {
      final phase = activePhase;
      if (phase != null) {
        emit(phase, OperationStatus.cancelled, 'Cancelled after cleanup');
      }
    } catch (error) {
      final phase = activePhase;
      if (phase != null) {
        emit(phase, OperationStatus.failed, error.toString());
      }
      rethrow;
    }
  }
}

final class _InstallLogSink implements LogSink {
  final void Function(String) onEvent;

  const _InstallLogSink(this.onEvent);

  @override
  void add(LogEvent event) => onEvent(event.message);

  @override
  LogProgress startProgress(String message) {
    onEvent(message);

    return _InstallLogProgress(onEvent);
  }
}

final class _InstallLogProgress implements LogProgress {
  final void Function(String) onEvent;

  const _InstallLogProgress(this.onEvent);

  @override
  void cancel([String? message]) => onEvent(message ?? 'Cancelled');

  @override
  void complete([String? message]) => onEvent(message ?? 'Complete');

  @override
  void fail([String? message]) => onEvent(message ?? 'Failed');
}
