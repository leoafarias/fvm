import 'dart:io';

import 'package:fvm/src/utils/constants.dart';
import 'package:grinder/grinder.dart';
import 'package:path/path.dart' as p;

import '../test/testing_helpers/prepare_test_environment.dart';

void main(List<String> args) => grind(args);

/// Shared test cache paths - must match test/testing_utils.dart
final _sharedTestFvmDir = p.join(kUserHome, 'fvm_test_cache');
final _sharedGitCacheDir = p.join(_sharedTestFvmDir, 'gitcache');

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

  // Create the git cache at the location tests expect (~/fvm_test_cache/gitcache)
  // This prevents tests from having to create it from scratch (which takes 10+ minutes)
  run(
    'dart',
    arguments: ['bin/main.dart', 'install', 'stable'],
    runOptions: RunOptions(
      environment: {
        'FVM_CACHE_PATH': _sharedTestFvmDir,
        'FVM_GIT_CACHE_PATH': _sharedGitCacheDir,
      },
    ),
  );
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
