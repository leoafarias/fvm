import 'package:grinder/grinder.dart';
import 'package:cli_pkg/cli_pkg.dart' as pkg;

void main(List<String> args) {
  pkg.name = 'fvm';
  pkg.humanName = 'fvm';
  pkg.githubUser = 'leoafarias';
  pkg.homebrewRepo = 'leoafarias/homebrew-fvm';
  pkg.addAllTasks();
  grind(args);
}
