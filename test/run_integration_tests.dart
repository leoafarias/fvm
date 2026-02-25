#!/usr/bin/env dart

import 'dart:io';

Future<void> main(List<String> args) async {
  print('🚀 FVM Integration Test Suite');
  print('==============================');
  
  final useOriginal = args.contains('--original');
  final performanceOnly = args.contains('--performance-only');
  final skipSerial = args.contains('--parallel-only');
  final verbose = args.contains('--verbose') || args.contains('-v');
  
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }
  
  if (useOriginal) {
    await _runOriginalTests(verbose: verbose);
    return;
  }
  
  if (performanceOnly) {
    await _runPerformanceTests(verbose: verbose);
    return;
  }
  
  await _runNewIntegrationTests(skipSerial: skipSerial, verbose: verbose);
}

void _printUsage() {
  print('''
Usage: dart test/run_integration_tests.dart [options]

Options:
  --help, -h           Show this help message
  --original           Run the original integration-test command for comparison
  --performance-only   Run only performance validation tests
  --parallel-only      Run only parallel tests (skip slow serial tests)
  --verbose, -v        Show verbose output

Examples:
  dart test/run_integration_tests.dart                    # Run new fast tests
  dart test/run_integration_tests.dart --original         # Run original slow tests
  dart test/run_integration_tests.dart --performance-only # Run performance validation
  dart test/run_integration_tests.dart --parallel-only    # Run only fast parallel tests
''');
}

Future<void> _runOriginalTests({bool verbose = false}) async {
  print('\n📊 Running original integration tests for comparison...');
  print('⚠️  WARNING: This may take 20-30 minutes and will modify your FVM cache!');
  
  final stopwatch = Stopwatch()..start();
  
  final result = await Process.run(
    'dart', 
    ['run', 'fvm', 'integration-test'],
    environment: Platform.environment,
  );
  
  stopwatch.stop();
  final elapsedMinutes = stopwatch.elapsedMilliseconds / 60000;
  
  if (result.exitCode != 0) {
    print('❌ Original integration tests failed');
    if (verbose) {
      print('STDOUT:\n${result.stdout}');
      print('STDERR:\n${result.stderr}');
    }
    exit(1);
  }
  
  print('✅ Original integration tests completed in ${elapsedMinutes.toStringAsFixed(1)} minutes');
  
  if (verbose) {
    print('\nOutput:\n${result.stdout}');
  }
}

Future<void> _runPerformanceTests({bool verbose = false}) async {
  print('\n⏱️ Running performance validation tests...');
  
  final result = await Process.run('dart', [
    'test',
    '--tags=performance',
    if (verbose) '--verbose',
    'test/integration/performance_test.dart',
  ]);
  
  if (result.exitCode != 0) {
    print('❌ Performance tests failed');
    if (verbose) {
      print('STDOUT:\n${result.stdout}');
      print('STDERR:\n${result.stderr}');
    }
    exit(1);
  }
  
  print('✅ Performance validation completed');
  
  if (verbose) {
    print('\nOutput:\n${result.stdout}');
  }
}

Future<void> _runNewIntegrationTests({bool skipSerial = false, bool verbose = false}) async {
  final stopwatch = Stopwatch()..start();
  
  // Run parallel tests first (fast)
  print('\n⚡ Running parallel tests (target: <3 min)...');
  final parallelStopwatch = Stopwatch()..start();
  
  final parallelResult = await Process.run('dart', [
    'test',
    '--tags=parallel',
    '--concurrency=3', // Conservative starting point
    if (verbose) '--verbose',
    'test/integration/parallel_integration_test.dart',
  ]);
  
  parallelStopwatch.stop();
  final parallelMinutes = parallelStopwatch.elapsedMilliseconds / 60000;
  
  if (parallelResult.exitCode != 0) {
    print('❌ Parallel tests failed!');
    print('STDOUT:\n${parallelResult.stdout}');
    print('STDERR:\n${parallelResult.stderr}');
    exit(1);
  }
  
  print('✅ Parallel tests completed in ${parallelMinutes.toStringAsFixed(1)} minutes');
  
  double? serialMinutes;
  
  if (!skipSerial) {
    // Run serial tests (slower but still much faster than original)
    print('\n🔄 Running serial tests (target: <8 min)...');
    final serialStopwatch = Stopwatch()..start();
    
    final serialResult = await Process.run('dart', [
      'test',
      '--tags=serial',
      '--concurrency=1',
      if (verbose) '--verbose',
      'test/integration/parallel_integration_test.dart',
    ]);
    
    serialStopwatch.stop();
    serialMinutes = serialStopwatch.elapsedMilliseconds / 60000;
    
    if (serialResult.exitCode != 0) {
      print('❌ Serial tests failed!');
      print('STDOUT:\n${serialResult.stdout}');
      print('STDERR:\n${serialResult.stderr}');
      exit(1);
    }
    
    print('✅ Serial tests completed in ${serialMinutes!.toStringAsFixed(1)} minutes');
  }
  
  stopwatch.stop();
  final totalMinutes = stopwatch.elapsedMilliseconds / 60000;
  
  // Print comprehensive results
  print('\n🎉 All integration tests passed!');
  print('📊 Performance Summary:');
  print('   Parallel tests: ${parallelMinutes.toStringAsFixed(1)} minutes');
  if (serialMinutes != null) {
    print('   Serial tests:   ${serialMinutes.toStringAsFixed(1)} minutes');
  }
  print('   Total time:     ${totalMinutes.toStringAsFixed(1)} minutes');
  print('   Target:         <5 minutes total');
  
  final targetMet = totalMinutes < 5;
  print('   Status:         ${targetMet ? "🎉 TARGET MET" : "⚠️  SLOWER THAN EXPECTED"}');
  
  if (targetMet) {
    final assumedOriginalTime = 30.0; // Estimated original test time
    final speedup = assumedOriginalTime / totalMinutes;
    print('   Est. speedup:   ${speedup.toStringAsFixed(1)}x faster than original');
    
    if (speedup >= 6) {
      print('   Performance:    🏆 EXCELLENT (6x+ speedup achieved)');
    } else if (speedup >= 4) {
      print('   Performance:    🎉 GREAT (4x+ speedup achieved)');  
    } else {
      print('   Performance:    ✅ GOOD (speedup achieved)');
    }
  }
  
  // Provide optimization suggestions
  if (parallelMinutes > 2) {
    print('\n💡 Optimization suggestions:');
    print('   - Consider increasing concurrency (currently 3)');
    print('   - Check if git cache is properly configured');
    print('   - Run: dart test/run_integration_tests.dart --performance-only');
  }
  
  if (verbose) {
    print('\n📝 Detailed output available in build/test-results.json');
  }
}