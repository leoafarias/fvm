import '../services/operation_cancellation.dart';
import 'fvm_tui_models.dart';

abstract interface class VersionsRepository {
  Future<TuiVersionsData> load();
}

abstract interface class ReleasesRepository {
  Future<List<TuiReleaseItem>> load();
}

abstract interface class UseVersionRunner {
  Future<void> run(UseVersionRequest request, void Function(String) onEvent);
}

abstract interface class InstallRunner {
  OperationCancellation createCancellation();

  Future<void> run(
    InstallRequest request, {
    required void Function(InstallProgressUpdate) onProgress,
    required OperationCancellation cancellation,
  });
}

abstract interface class DoctorRepository {
  Future<TuiDoctorReport> load();
}

abstract interface class ConfigurationRepository {
  Future<TuiConfiguration> load(ConfigurationScope scope);

  Future<TuiConfiguration> save(TuiConfigurationPatch patch);
}
