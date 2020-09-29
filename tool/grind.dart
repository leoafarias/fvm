import 'package:grinder/grinder.dart';
import 'package:cli_pkg/cli_pkg.dart' as pkg;

void main(List<String> args) {
  pkg.addAllTasks();
  grind(args);
}

@Task()
void test() => TestRunner().testAsync();

@DefaultTask()
@Depends(test)
void build() {
  Pub.build();
}

@Task()
void clean() => defaultClean();
