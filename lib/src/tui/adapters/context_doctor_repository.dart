import '../../services/doctor_service.dart';
import '../fvm_tui_models.dart';
import '../fvm_tui_ports.dart';
import 'fvm_context_handle.dart';

final class ContextDoctorRepository implements DoctorRepository {
  final FvmContextHandle contextHandle;

  const ContextDoctorRepository(this.contextHandle);

  DoctorSection _mapSection(DoctorReportSection section) {
    final checks = section.checks
        .map(
          (check) => (
            label: check.label,
            value: check.value,
            tone: _tone(check.status),
          ),
        )
        .toList();

    return (
      name: section.name,
      tone: _sectionTone(section.checks),
      checks: checks,
    );
  }

  TuiTone _sectionTone(List<DoctorReportCheck> checks) {
    if (checks.any((check) => check.status == DoctorStatus.error)) {
      return TuiTone.error;
    }
    if (checks.any((check) => check.status == DoctorStatus.warning)) {
      return TuiTone.warning;
    }
    if (checks.any((check) => check.status == DoctorStatus.info)) {
      return TuiTone.info;
    }

    return TuiTone.success;
  }

  TuiTone _tone(DoctorStatus status) => switch (status) {
    DoctorStatus.ok => TuiTone.success,
    DoctorStatus.info => TuiTone.info,
    DoctorStatus.warning => TuiTone.warning,
    DoctorStatus.error => TuiTone.error,
  };

  @override
  Future<TuiDoctorReport> load() async {
    final report = contextHandle.current.get<DoctorService>().inspect();

    return (
      sections: report.sections.map(_mapSection).toList(),
      recommendations: report.recommendations,
    );
  }
}
