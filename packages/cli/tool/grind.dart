import 'package:grinder/grinder.dart';
import 'package:cli_pkg/cli_pkg.dart' as pkg;
import 'package:dotenv/dotenv.dart' show env;

void main(List<String> args) {
  pkg.name = 'fvm';
  pkg.humanName = 'fvm';
  pkg.githubUser = env['GITHUB_USERNAME'];
  pkg.githubPassword = env['GITHUB_PASSWORD'];
  pkg.chocolateyNuspec = 'fvm.nuspec';

  pkg.addAllTasks();
  grind(args);
}
