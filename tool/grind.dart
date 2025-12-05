import 'dart:io';

import 'package:grinder/grinder.dart';

import '../test/testing_helpers/prepare_test_environment.dart';

void main(List<String> args) => grind(args);

@Task('Compile')
void compile() {
  run('dart', arguments: ['compile', 'exe', 'bin/main.dart', '-o', 'fvm']);
}

@Task('Prepare test environment')
void testSetup() {
  final testDir = Directory(getTempTestDir());
  if (testDir.existsSync()) {
    testDir.deleteSync(recursive: true);
  }

  runDartScript('bin/main.dart', arguments: ['install', 'stable']);
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
