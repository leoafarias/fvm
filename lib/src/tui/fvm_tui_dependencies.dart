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
