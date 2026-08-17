import '../utils/context.dart';
import 'adapters/context_configuration_repository.dart';
import 'adapters/context_doctor_repository.dart';
import 'adapters/context_install_runner.dart';
import 'adapters/context_releases_repository.dart';
import 'adapters/context_use_version_runner.dart';
import 'adapters/context_versions_repository.dart';
import 'adapters/fvm_context_handle.dart';
import 'fvm_tui_ports.dart';

final class FvmTuiDependencies {
  final VersionsRepository versions;
  final ReleasesRepository releases;
  final UseVersionRunner useVersion;
  final InstallRunner install;
  final DoctorRepository doctor;
  final ConfigurationRepository configuration;

  const FvmTuiDependencies({
    required this.versions,
    required this.releases,
    required this.useVersion,
    required this.install,
    required this.doctor,
    required this.configuration,
  });
}

FvmTuiDependencies createFvmTuiDependencies(FvmContext context) {
  final contextHandle = FvmContextHandle(
    context,
    reload: reloadFvmContextFromDisk,
  );

  return FvmTuiDependencies(
    versions: ContextVersionsRepository(contextHandle),
    releases: ContextReleasesRepository(contextHandle),
    useVersion: ContextUseVersionRunner(contextHandle),
    install: ContextInstallRunner(contextHandle),
    doctor: ContextDoctorRepository(contextHandle),
    configuration: ContextConfigurationRepository(contextHandle),
  );
}
