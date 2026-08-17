import 'dart:async';

import 'package:fvm/src/services/operation_cancellation.dart';
import 'package:fvm/src/tui/fvm_tui_dependencies.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:fvm/src/tui/fvm_tui_ports.dart';

final threeVersions = <TuiVersionItem>[
  (
    id: 'stable',
    version: '3.35.1',
    channel: 'stable',
    metadata: 'global',
    installed: true,
    isGlobal: true,
    isProject: false,
    needsSetup: false,
  ),
  (
    id: 'beta',
    version: '3.36.0-0.1.pre',
    channel: 'beta',
    metadata: 'preview',
    installed: true,
    isGlobal: false,
    isProject: false,
    needsSetup: false,
  ),
  (
    id: '3.32.8',
    version: '3.32.8',
    channel: 'release',
    metadata: 'project',
    installed: true,
    isGlobal: false,
    isProject: true,
    needsSetup: false,
  ),
];

final oneVersion = <TuiVersionItem>[threeVersions.first];

final class FakeTuiPorts {
  FakeTuiPorts({
    List<List<TuiVersionItem>>? versionBatches,
    List<TuiReleaseItem>? releaseItems,
    this.versionsError,
    this.blockInstall = false,
  }) : versionBatches = versionBatches ?? [threeVersions],
       releaseItems = releaseItems ?? const [];

  factory FakeTuiPorts.withReadyData() => FakeTuiPorts();

  List<List<TuiVersionItem>> versionBatches;
  final List<TuiReleaseItem> releaseItems;
  final Object? versionsError;
  final bool blockInstall;
  final List<UseVersionRequest> useRequests = [];
  final List<InstallRequest> installRequests = [];
  final List<TuiConfigurationPatch> configurationPatches = [];
  final installStarted = Completer<void>();
  final _installCompletion = Completer<void>();
  _FakeCancellation? _installCancellation;
  int versionsLoadCount = 0;
  int releasesLoadCount = 0;

  late final FvmTuiDependencies dependencies = FvmTuiDependencies(
    versions: _FakeVersionsRepository(this),
    releases: _FakeReleasesRepository(this),
    useVersion: _FakeUseVersionRunner(this),
    install: _FakeInstallRunner(this),
    doctor: _FakeDoctorRepository(),
    configuration: _FakeConfigurationRepository(this),
  );

  bool get installCancelled => _installCancellation?.isCancelled ?? false;

  void completeInstall() {
    if (!_installCompletion.isCompleted) _installCompletion.complete();
  }
}

final class _FakeVersionsRepository implements VersionsRepository {
  _FakeVersionsRepository(this.ports);

  final FakeTuiPorts ports;

  @override
  Future<TuiVersionsData> load() async {
    final error = ports.versionsError;
    if (error != null) throw error;
    final index = ports.versionsLoadCount.clamp(
      0,
      ports.versionBatches.length - 1,
    );
    ports.versionsLoadCount += 1;
    return (
      items: ports.versionBatches[index],
      cachePath: '/tmp/fvm/versions',
      cacheBytes: 0,
      updateMessage: null,
    );
  }
}

final class _FakeReleasesRepository implements ReleasesRepository {
  _FakeReleasesRepository(this.ports);

  final FakeTuiPorts ports;

  @override
  Future<List<TuiReleaseItem>> load() async {
    ports.releasesLoadCount += 1;
    return ports.releaseItems;
  }
}

final class _FakeUseVersionRunner implements UseVersionRunner {
  _FakeUseVersionRunner(this.ports);

  final FakeTuiPorts ports;

  @override
  Future<void> run(
    UseVersionRequest request,
    void Function(String) onEvent,
  ) async {
    ports.useRequests.add(request);
    onEvent('using ${request.version}');
  }
}

final class _FakeInstallRunner implements InstallRunner {
  _FakeInstallRunner(this.ports);

  final FakeTuiPorts ports;

  @override
  OperationCancellation createCancellation() =>
      ports._installCancellation = _FakeCancellation();

  @override
  Future<void> run(
    InstallRequest request, {
    required void Function(InstallProgressUpdate) onProgress,
    required OperationCancellation cancellation,
  }) async {
    ports.installRequests.add(request);
    if (!ports.installStarted.isCompleted) ports.installStarted.complete();
    onProgress((
      phase: InstallPhase.ensureCache,
      status: OperationStatus.active,
      detail: 'Preparing install',
      exactPercent: null,
    ));
    if (ports.blockInstall) await ports._installCompletion.future;
  }
}

final class _FakeDoctorRepository implements DoctorRepository {
  @override
  Future<TuiDoctorReport> load() async =>
      (sections: const <DoctorSection>[], recommendations: const <String>[]);
}

final class _FakeConfigurationRepository implements ConfigurationRepository {
  _FakeConfigurationRepository(this.ports);

  final FakeTuiPorts ports;

  @override
  Future<TuiConfiguration> load(ConfigurationScope scope) async => (
    scope: scope,
    cachePath: '/tmp/fvm/versions',
    gitCachePath: '/tmp/fvm/git',
    runPubGetOnSdkChanges: true,
    updateVscodeSettings: true,
    updateGitIgnore: true,
    updateMelosSettings: true,
    useGitCache: true,
    updateCheckEnabled: scope == ConfigurationScope.global ? true : null,
    overriddenFields: scope == ConfigurationScope.project
        ? const <TuiConfigurationField>{TuiConfigurationField.cachePath}
        : TuiConfigurationField.values.toSet(),
  );

  @override
  Future<TuiConfiguration> save(TuiConfigurationPatch patch) async {
    ports.configurationPatches.add(patch);

    return load(patch.scope);
  }
}

final class _FakeCancellation implements OperationCancellation {
  @override
  bool isCancelled = false;

  @override
  void cancel() => isCancelled = true;
}
