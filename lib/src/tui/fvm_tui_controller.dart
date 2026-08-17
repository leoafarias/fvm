import 'package:noir/noir.dart';

import '../services/operation_cancellation.dart';
import 'fvm_tui_dependencies.dart';
import 'fvm_tui_models.dart';

final class FvmTuiController extends ChangeNotifier {
  final FvmTuiDependencies _dependencies;
  final Set<FvmTuiRoute> _loadedRoutes = {};
  final List<String> _operationEvents = [];
  final List<InstallProgressUpdate> _installProgress = [];

  FvmTuiRoute _route = FvmTuiRoute.versions;
  bool _loading = false;
  bool _disposed = false;
  Object? _error;
  TuiVersionsData? _versions;
  List<TuiReleaseItem>? _releases;
  TuiDoctorReport? _doctor;
  TuiConfiguration? _configuration;
  int _selectedVersionIndex = 0;
  int _selectedReleaseIndex = 0;
  OperationCancellation? _activeInstallCancellation;

  FvmTuiController({required FvmTuiDependencies dependencies})
    : _dependencies = dependencies;

  static int _clampIndex(int index, int length) {
    if (length == 0) return 0;

    return index.clamp(0, length - 1);
  }

  Future<void> _loadRoute(FvmTuiRoute route, {bool force = false}) async {
    if (!force && _loadedRoutes.contains(route)) return;
    await _run(() async {
      switch (route) {
        case FvmTuiRoute.versions:
          _versions = await _dependencies.versions.load();
          _selectedVersionIndex = _clampIndex(
            _selectedVersionIndex,
            _versions!.items.length,
          );
        case FvmTuiRoute.releases:
          _releases = await _dependencies.releases.load();
          _selectedReleaseIndex = _clampIndex(
            _selectedReleaseIndex,
            _releases!.length,
          );
        case FvmTuiRoute.doctor:
          _doctor = await _dependencies.doctor.load();
        case FvmTuiRoute.configuration:
          _configuration = await _dependencies.configuration.load(
            ConfigurationScope.global,
          );
        case FvmTuiRoute.useVersion:
        case FvmTuiRoute.installOptions:
        case FvmTuiRoute.installProgress:
          break;
      }
      _loadedRoutes.add(route);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_disposed) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _recordOperationEvent(String event) {
    if (_disposed) return;
    _operationEvents.add(event);
    notifyListeners();
  }

  FvmTuiRoute get route => _route;
  bool get loading => _loading;
  Object? get error => _error;
  TuiVersionsData? get versions => _versions;
  List<TuiReleaseItem>? get releases => _releases;
  TuiDoctorReport? get doctor => _doctor;
  TuiConfiguration? get configuration => _configuration;
  int get selectedVersionIndex => _selectedVersionIndex;
  int get selectedReleaseIndex => _selectedReleaseIndex;
  bool get hasActiveInstall => _activeInstallCancellation != null;
  List<String> get operationEvents => List.unmodifiable(_operationEvents);
  List<InstallProgressUpdate> get installProgress =>
      List.unmodifiable(_installProgress);

  Future<void> initialize() => _loadRoute(_route);

  Future<void> goTo(FvmTuiRoute route) async {
    if (_disposed) return;
    if (_route != route) {
      _route = route;
      notifyListeners();
    }
    if (!_loadedRoutes.contains(route)) await _loadRoute(route);
  }

  Future<void> refresh() => _loadRoute(_route, force: true);

  Future<void> useVersion(UseVersionRequest request) => _run(() async {
    _operationEvents.clear();
    await _dependencies.useVersion.run(request, _recordOperationEvent);
  });

  Future<void> install(InstallRequest request) async {
    if (_disposed || _activeInstallCancellation != null) return;
    final cancellation = _dependencies.install.createCancellation();
    _activeInstallCancellation = cancellation;
    _operationEvents.clear();
    _installProgress.clear();
    _error = null;
    _route = FvmTuiRoute.installProgress;
    notifyListeners();
    try {
      await _dependencies.install.run(
        request,
        cancellation: cancellation,
        onProgress: (update) {
          if (_disposed) return;
          _installProgress.add(update);
          if (update.detail.isNotEmpty) {
            _operationEvents.add(update.detail);
          }
          notifyListeners();
        },
      );
    } catch (error) {
      _error = error;
    } finally {
      if (identical(_activeInstallCancellation, cancellation)) {
        _activeInstallCancellation = null;
      }
      if (!_disposed) notifyListeners();
    }
  }

  void selectVersion(int index) {
    final length = _versions?.items.length ?? 0;
    final next = _clampIndex(index, length);
    if (_disposed || next == _selectedVersionIndex) return;
    _selectedVersionIndex = next;
    notifyListeners();
  }

  void selectRelease(int index) {
    final length = _releases?.length ?? 0;
    final next = _clampIndex(index, length);
    if (_disposed || next == _selectedReleaseIndex) return;
    _selectedReleaseIndex = next;
    notifyListeners();
  }

  void cancelInstall() => _activeInstallCancellation?.cancel();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _activeInstallCancellation?.cancel();
    _activeInstallCancellation = null;
    super.dispose();
  }
}
