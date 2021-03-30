import 'package:grinder/grinder.dart';
import 'package:cli_pkg/cli_pkg.dart' as pkg;

void main(List<String> args) {
  pkg.name.value = 'fvm';
  pkg.humanName.value = 'fvm';
  pkg.githubUser.value = 'leoafarias';
  pkg.homebrewRepo.value = 'leoafarias/homebrew-fvm';

  pkg.addAllTasks();
  grind(args);
}
