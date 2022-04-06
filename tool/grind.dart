import 'package:cli_pkg/cli_pkg.dart' as pkg;
import 'package:grinder/grinder.dart';

void main(List<String> args) {
  pkg.name.value = 'fvm';
  pkg.humanName.value = 'fvm';
  pkg.githubUser.value = 'fluttertools';
  pkg.homebrewRepo.value = 'leoafarias/homebrew-fvm';

  pkg.addAllTasks();
  grind(args);
}
