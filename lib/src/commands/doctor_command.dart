import 'package:dart_console/dart_console.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

import '../services/doctor_service.dart';
import '../utils/console_utils.dart';
import '../utils/constants.dart';
import 'base_command.dart';

/// Information about fvm environment.
class DoctorCommand extends BaseFvmCommand {
  @override
  final name = 'doctor';

  @override
  final description =
      'Shows detailed information about the FVM environment and project configuration';

  final console = Console();

  DoctorCommand(super.context);

  void _printProject(DoctorReportSection section) {
    logger.info('Project:');
    final directory = section.checks
        .firstWhere((check) => check.label == 'Directory')
        .value;
    final table = createTable(['Project', path.basename(directory)]);
    table.insertRows(
      section.checks.map((check) => [check.label, check.value]).toList(),
    );
    logger
      ..write(table.toString())
      ..info();
  }

  void _printIdeLinks(DoctorReportSection section) {
    logger
      ..info()
      ..info('IDEs:');
    final table = createTable(['IDEs', 'Value'])..insertRow([kVsCode]);
    final vscodeChecks = section.checks.where(
      (check) => check.label.startsWith('VS Code'),
    );
    for (final check in vscodeChecks) {
      table.insertRow([_ideLabel(check.label), check.value]);
    }

    table.insertRow([kIntelliJ]);
    final intellijChecks = section.checks.where(
      (check) => check.label.startsWith('IntelliJ'),
    );
    for (final check in intellijChecks) {
      table.insertRow([_ideLabel(check.label), check.value]);
    }
    logger.write(table.toString());
  }

  String _ideLabel(String label) => switch (label) {
    'VS Code' => kVsCode,
    'VS Code settings' => 'settings.json',
    'VS Code SDK path' => 'dart.flutterSdkPath',
    'VS Code pinned version' ||
    'IntelliJ pinned version' => 'Matches pinned version:',
    'IntelliJ flutter.sdk' => 'flutter.sdk',
    'IntelliJ SDK Path' => 'SDK Path',
    _ => label,
  };

  void _printEnvironmentDetails(
    DoctorReportSection environment,
    DoctorReportSection runtime,
  ) {
    logger
      ..info()
      ..info('Environment:');

    final environmentTable = createTable(['Environment Variables', 'Value'])
      ..insertRows(
        environment.checks.map((check) => [check.label, check.value]).toList(),
      );
    logger.write(environmentTable.toString());

    final runtimeTable = createTable(['Platform', 'Value'])
      ..insertRows(
        runtime.checks.map((check) => [check.label, check.value]).toList(),
      );
    logger.write(runtimeTable.toString());
  }

  @override
  Future<int> run() async {
    final report = get<DoctorService>().inspect();
    final sections = {
      for (final section in report.sections) section.name: section,
    };

    console.writeLine('FVM Doctor:');
    console.writeLine('-' * console.windowWidth);

    _printProject(sections['Project']!);
    _printIdeLinks(sections['IDEs']!);
    _printEnvironmentDetails(sections['Environment']!, sections['Runtime']!);

    return ExitCode.success.code;
  }
}
