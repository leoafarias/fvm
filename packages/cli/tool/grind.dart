import 'package:grinder/grinder.dart';
import 'package:cli_pkg/cli_pkg.dart' as pkg;
import 'package:dotenv/dotenv.dart' show env;

void main(List<String> args) {
  pkg.name = 'fvm';
  pkg.humanName = 'fvm';
  pkg.githubUser = 'leoafarias';
  pkg.githubPassword = env['GITHUB_TOKEN'];
  pkg.homebrewRepo = 'leoafarias/homebrew-fvm';

  pkg.addAllTasks();
  grind(args);
}
