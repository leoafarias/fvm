import 'dart:convert';
import 'dart:io';

import 'package:cli_pkg/cli_pkg.dart' as pkg;
import 'package:fvm/src/utils/http.dart';
import 'package:grinder/grinder.dart';
import 'package:path/path.dart' as path;

import '../test/testing_helpers/prepare_test_environment.dart';

const _packageName = 'fvm';
const owner = 'leoafarias';
const repo = 'fvm';

void main(List<String> args) {
  pkg.name.value = _packageName;
  pkg.humanName.value = _packageName;
  pkg.useExe.value = (_) => true;
  pkg.githubUser.value = owner;
  pkg.githubRepo.value = '$owner/$_packageName';
  pkg.homebrewRepo.value = '$owner/homebrew-$_packageName';
  pkg.githubBearerToken.value = Platform.environment['GITHUB_TOKEN'];

  // Enable standalone executables for all platforms
  pkg.standaloneName.value = _packageName;

  if (args.contains('--versioned-formula')) {
    pkg.homebrewCreateVersionedFormula.value = true;
  }

  pkg.addAllTasks();

  grind(args);
}

@Task('Compile')
void compile() {
  run('dart', arguments: ['compile', 'exe', 'bin/main.dart', '-o', 'fvm']);
}

@Task('Get all releases')
Future<void> getReleases() async {
  String owner = 'leoafarias';
  String repo = 'fvm';

  final response = await httpRequest(
    'https://api.github.com/repos/$owner/$repo/releases?per_page=100',
    headers: {'Accept': 'application/vnd.github.v3+json'},
  );

  final stringBuffer = StringBuffer();

  List releases = jsonDecode(response);
  for (var release in releases) {
    String tagName = release['tag_name'];
    String date = release['published_at'];
    print('Release: $tagName, Date: $date');
    stringBuffer.writeln('Release: $tagName, Date: $date');
  }

  final file = File(path.join(Directory.current.path, 'releases.txt'));

  file.writeAsStringSync(stringBuffer.toString());
}

@Task('Prepare test environment')
void testSetup() {
  final testDir = Directory(getTempTestDir());
  if (testDir.existsSync()) {
    testDir.deleteSync(recursive: true);
  }

  runDartScript('bin/main.dart', arguments: ['install', 'stable']);
}

@Task('Move install scripts to public directory')
void moveScripts() {
  final installScript = File('scripts/install.sh');

  if (!installScript.existsSync()) {
    throw Exception('Install or uninstall script does not exist');
  }

  final publicDir = Directory('docs/public');

  if (!publicDir.existsSync()) {
    throw Exception('Public directory does not exist');
  }

  installScript.copySync(path.join(publicDir.path, 'install.sh'));

  print('Moved install.sh to public directory');
}

@Task('Run tests')
@Depends(testSetup)
Future<void> test() async {
  await runAsync('dart', arguments: ['test', '--coverage=coverage']);
}

@Task('Get coverage')
Future<void> coverage() async {
  await runAsync('dart', arguments: ['pub', 'global', 'activate', 'coverage']);

  // Format coverage
  await runAsync(
    'dart',
    arguments: [
      'pub',
      'global',
      'run',
      'coverage:format_coverage',
      '--lcov',
      '--packages=.dart_tool/package_config.json',
      '--report-on=lib/',
      '--in=coverage',
      '--out=coverage/lcov.info',
    ],
  );
}

@Task('Run integration tests')
Future<void> integrationTest() async {
  print('Running integration tests...');

  // Run integration tests using the new Dart command
  await runAsync(
    'dart',
    arguments: ['run', 'bin/main.dart', 'integration-test'],
  );

  print('Integration tests completed successfully');
}

@Task('Run all tests (unit + integration)')
@Depends(test, integrationTest)
void testAll() {
  print('All tests completed successfully');
}
