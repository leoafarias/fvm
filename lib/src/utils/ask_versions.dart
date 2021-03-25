import 'package:cli_dialog/cli_dialog.dart';
import 'package:fvm/fvm.dart';

String askWhichVersion(List<CacheVersion> versions) {
  final versionNames = versions.map((version) => version.name).toList();
  final listQuestions = [
    [
      {
        'question': 'Select version',
        'options': versionNames,
      },
      'version'
    ]
  ];
  final dialog = CLI_Dialog(listQuestions: listQuestions);
  final answer = dialog.ask();
  return answer['version'] as String;
}
