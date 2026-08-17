import 'package:fvm/src/services/doctor_service.dart';
import 'package:fvm/src/tui/adapters/context_doctor_repository.dart';
import 'package:fvm/src/tui/adapters/fvm_context_handle.dart';
import 'package:fvm/src/tui/fvm_tui_models.dart';
import 'package:fvm/src/tui/screens/doctor_screen.dart';
import 'package:noir/noir.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  test('repository maps service statuses to TUI tones', () async {
    final context = TestFactory.fastContext(
      generators: {DoctorService: _FakeDoctorService.new},
    );
    final repository = ContextDoctorRepository(
      FvmContextHandle(context, reload: (previous) => previous),
    );

    final report = await repository.load();

    expect(report.sections.single.tone, TuiTone.error);
    expect(report.sections.single.checks.map((check) => check.tone), [
      TuiTone.success,
      TuiTone.info,
      TuiTone.warning,
      TuiTone.error,
    ]);
  });

  test(
    'wide and compact layouts mount and Enter expands only a recommendation',
    () {
      final report = (
        sections: const <DoctorSection>[],
        recommendations: const ['fvm use stable', '/tmp/.vscode/settings.json'],
      );
      for (final mode in FvmTuiLayoutMode.values) {
        final key = GlobalKey<DoctorScreenState>();
        final app = runTuiApp(
          DoctorScreen(key: key, report: report, layoutMode: mode),
          width: mode == FvmTuiLayoutMode.wide ? 120 : 72,
          height: 30,
          headless: true,
        );

        key.currentState!
          ..selectRecommendation(1)
          ..expandSelected();

        expect(key.currentState!.expandedRecommendationIndex, 1);
        app.dispose();
      }
    },
  );
}

final class _FakeDoctorService extends DoctorService {
  _FakeDoctorService(super.context);

  @override
  DoctorReport inspect() => const DoctorReport(
    sections: [
      DoctorReportSection(
        name: 'Checks',
        checks: [
          DoctorReportCheck(label: 'ok', value: 'yes', status: DoctorStatus.ok),
          DoctorReportCheck(
            label: 'info',
            value: 'detail',
            status: DoctorStatus.info,
          ),
          DoctorReportCheck(
            label: 'warning',
            value: 'careful',
            status: DoctorStatus.warning,
          ),
          DoctorReportCheck(
            label: 'error',
            value: 'broken',
            status: DoctorStatus.error,
          ),
        ],
      ),
    ],
    recommendations: ['fvm use stable'],
  );
}
