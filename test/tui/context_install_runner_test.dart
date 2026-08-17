import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/install_observer.dart';
import 'package:fvm/src/services/operation_cancellation.dart';
import 'package:fvm/src/services/process_service.dart';
import 'package:fvm/src/tui/adapters/context_install_runner.dart';
import 'package:fvm/src/tui/adapters/fvm_context_handle.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:fvm/src/workflows/setup_flutter.workflow.dart';
import 'package:fvm/src/workflows/use_version.workflow.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  const request = (
    version: '3.10.0',
    useGitCache: false,
    runSetup: true,
    useAfterInstall: true,
    force: true,
  );

  test(
    'emits the six-phase install sequence with clone-only percentages',
    () async {
      late _ObservedEnsureCache ensure;
      late _RecordedSetupFlutter setup;
      late _RecordedUseVersion use;
      final operationContext = TestFactory.fastContext(
        skipInput: true,
        generators: {
          EnsureCacheWorkflow: (context) =>
              ensure = _ObservedEnsureCache(context),
          SetupFlutterWorkflow: (context) =>
              setup = _RecordedSetupFlutter(context),
          UseVersionWorkflow: (context) => use = _RecordedUseVersion(context),
        },
      );
      final runner = ContextInstallRunner(
        FvmContextHandle(operationContext, reload: (previous) => previous),
        operationContextFactory: (_) => operationContext,
      );
      final cancellation = runner.createCancellation();
      final updates = <InstallProgressUpdate>[];

      await runner.run(
        request,
        onProgress: updates.add,
        cancellation: cancellation,
      );

      expect(ensure.useGitCache, isFalse);
      expect(ensure.force, isTrue);
      expect(ensure.cancellation, same(cancellation));
      expect(setup.calls, ['3.10.0']);
      expect(use.calls, ['3.10.0']);
      expect(
        updates.take(6).map((update) => update.phase),
        InstallPhase.values,
      );
      expect(
        updates.take(6).map((update) => update.status),
        everyElement(OperationStatus.pending),
      );
      expect(
        updates
            .where((update) => update.exactPercent != null)
            .map((update) => (update.phase, update.exactPercent)),
        [(InstallPhase.cloneSdk, 42)],
      );
      for (final phase in InstallPhase.values) {
        expect(
          updates.where(
            (update) =>
                update.phase == phase &&
                update.status == OperationStatus.complete,
          ),
          isNotEmpty,
        );
      }
    },
  );

  test(
    'marks the active phase cancelled and leaves later phases pending',
    () async {
      late _ObservedEnsureCache ensure;
      final operationContext = TestFactory.fastContext(
        skipInput: true,
        generators: {
          EnsureCacheWorkflow: (context) =>
              ensure = _ObservedEnsureCache(context, cancelDuringClone: true),
        },
      );
      final runner = ContextInstallRunner(
        FvmContextHandle(operationContext, reload: (previous) => previous),
        operationContextFactory: (_) => operationContext,
      );
      final updates = <InstallProgressUpdate>[];

      await runner.run(
        request,
        onProgress: updates.add,
        cancellation: runner.createCancellation(),
      );

      expect(ensure.wasCancelled, isTrue);
      expect(
        updates
            .lastWhere((update) => update.phase == InstallPhase.cloneSdk)
            .status,
        OperationStatus.cancelled,
      );
      expect(
        updates.where(
          (update) =>
              update.phase == InstallPhase.setupFlutter &&
              update.status != OperationStatus.pending,
        ),
        isEmpty,
      );
    },
  );

  test(
    'rejects cancellation implementations it cannot attach to a process',
    () async {
      final operationContext = TestFactory.fastContext(skipInput: true);
      final runner = ContextInstallRunner(
        FvmContextHandle(operationContext, reload: (previous) => previous),
        operationContextFactory: (_) => operationContext,
      );

      await expectLater(
        runner.run(
          request,
          onProgress: (_) {},
          cancellation: _ForeignCancellation(),
        ),
        throwsArgumentError,
      );
    },
  );
}

final class _ObservedEnsureCache extends EnsureCacheWorkflow {
  _ObservedEnsureCache(super.context, {this.cancelDuringClone = false});

  final bool cancelDuringClone;
  bool? useGitCache;
  bool? force;
  ProcessCancellation? cancellation;
  bool wasCancelled = false;

  @override
  Future<CacheFlutterVersion> call(
    FlutterVersion version, {
    bool shouldInstall = false,
    bool force = false,
    int retryCount = 0,
    bool? useGitCache,
    InstallObserver? observer,
    ProcessCancellation? cancellation,
  }) async {
    this.useGitCache = useGitCache;
    this.force = force;
    this.cancellation = cancellation;
    observer
      ?..onUpdate((
        phase: InstallObservationPhase.acquireLock,
        status: InstallObservationStatus.active,
        detail: 'Waiting for lock',
        gitProgress: null,
      ))
      ..onUpdate((
        phase: InstallObservationPhase.acquireLock,
        status: InstallObservationStatus.complete,
        detail: 'Lock acquired',
        gitProgress: null,
      ))
      ..onUpdate((
        phase: InstallObservationPhase.cloneSdk,
        status: InstallObservationStatus.active,
        detail: 'Clone started',
        gitProgress: null,
      ))
      ..onUpdate((
        phase: InstallObservationPhase.cloneSdk,
        status: InstallObservationStatus.active,
        detail: 'Receiving objects: 42%',
        gitProgress: (
          phase: 'Receiving objects:',
          percent: 42,
          line: 'Receiving objects: 42%',
        ),
      ));
    if (cancelDuringClone) {
      cancellation!.cancel();
      wasCancelled = true;
      throw const OperationCanceledException();
    }
    observer
      ?..onUpdate((
        phase: InstallObservationPhase.cloneSdk,
        status: InstallObservationStatus.complete,
        detail: 'Clone complete',
        gitProgress: null,
      ))
      ..onUpdate((
        phase: InstallObservationPhase.validateRevision,
        status: InstallObservationStatus.active,
        detail: 'Validation started',
        gitProgress: null,
      ))
      ..onUpdate((
        phase: InstallObservationPhase.validateRevision,
        status: InstallObservationStatus.complete,
        detail: 'Validation complete',
        gitProgress: null,
      ));

    return CacheFlutterVersion(
      version.name,
      releaseChannel: version.releaseChannel,
      type: version.type,
      fork: version.fork,
      directory: path.join(context.versionsCachePath, version.name),
      flutterSdkVersion: version.version,
      dartSdkVersion: '3.0.0',
      isSetup: false,
    );
  }
}

final class _RecordedSetupFlutter extends SetupFlutterWorkflow {
  _RecordedSetupFlutter(super.context);

  final calls = <String>[];

  @override
  Future<void> call(CacheFlutterVersion version) async =>
      calls.add(version.name);
}

final class _RecordedUseVersion extends UseVersionWorkflow {
  _RecordedUseVersion(super.context);

  final calls = <String>[];

  @override
  Future<void> call({
    required CacheFlutterVersion version,
    required Project project,
    bool force = false,
    bool skipSetup = false,
    bool skipPubGet = false,
    String? flavor,
    bool? updateVscodeSettings,
    bool? updateMelosSettings,
    bool? configureMissingMelos,
    bool? updateExistingMelos,
  }) async => calls.add(version.name);
}

final class _ForeignCancellation implements OperationCancellation {
  @override
  bool isCancelled = false;

  @override
  void cancel() => isCancelled = true;
}
