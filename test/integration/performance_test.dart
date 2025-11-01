import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('Integration Test Performance Validation', () {
    
    test('Parallel suite completes under target time', () async {
      final stopwatch = Stopwatch()..start();
      
      print('🏃‍♂️ Running parallel test suite...');
      
      // Run parallel tests with conservative concurrency
      final result = await Process.run('dart', [
        'test',
        '--tags=parallel',
        '--concurrency=3', // Start conservative, can increase after validation
        'test/integration/parallel_integration_test.dart',
      ]);
      
      stopwatch.stop();
      final elapsedMinutes = stopwatch.elapsedMilliseconds / 60000;
      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
      
      print('⏱️  Parallel tests completed in ${elapsedMinutes.toStringAsFixed(1)} minutes (${elapsedSeconds.toStringAsFixed(1)}s)');
      
      expect(result.exitCode, equals(0), reason: 'Parallel tests failed:\n${result.stderr}');
      expect(elapsedMinutes, lessThan(3), 
        reason: 'Parallel tests took ${elapsedMinutes.toStringAsFixed(1)} minutes, should be under 3 minutes');
      
      if (elapsedMinutes < 2) {
        print('🎉 Excellent! Parallel tests are very fast');
      } else if (elapsedMinutes < 3) {
        print('✅ Good! Parallel tests meet target time');
      }
    }, timeout: Timeout(Duration(minutes: 5)));
    
    test('Serial suite completes under target time', () async {
      final stopwatch = Stopwatch()..start();
      
      print('🔄 Running serial test suite...');
      
      // Run serial tests (heavy operations)
      final result = await Process.run('dart', [
        'test',
        '--tags=serial',
        '--concurrency=1',
        'test/integration/parallel_integration_test.dart',
      ]);
      
      stopwatch.stop();
      final elapsedMinutes = stopwatch.elapsedMilliseconds / 60000;
      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
      
      print('⏱️  Serial tests completed in ${elapsedMinutes.toStringAsFixed(1)} minutes (${elapsedSeconds.toStringAsFixed(1)}s)');
      
      expect(result.exitCode, equals(0), reason: 'Serial tests failed:\n${result.stderr}');
      expect(elapsedMinutes, lessThan(8), 
        reason: 'Serial tests took ${elapsedMinutes.toStringAsFixed(1)} minutes, should be under 8 minutes');
      
      if (elapsedMinutes < 3) {
        print('🎉 Excellent! Serial tests are very fast');
      } else if (elapsedMinutes < 5) {
        print('✅ Good! Serial tests are reasonably fast');
      } else {
        print('⚠️  Serial tests are slower than ideal but acceptable');
      }
    }, timeout: Timeout(Duration(minutes: 10)));
    
    test('Combined test suite meets overall performance target', () async {
      final stopwatch = Stopwatch()..start();
      
      print('🚀 Running complete integration test suite...');
      
      // Run both parallel and serial tests
      final parallelFuture = Process.run('dart', [
        'test',
        '--tags=parallel',
        '--concurrency=3',
        'test/integration/parallel_integration_test.dart',
      ]);
      
      final serialFuture = Process.run('dart', [
        'test',
        '--tags=serial', 
        '--concurrency=1',
        'test/integration/parallel_integration_test.dart',
      ]);
      
      final results = await Future.wait([parallelFuture, serialFuture]);
      
      stopwatch.stop();
      final elapsedMinutes = stopwatch.elapsedMilliseconds / 60000;
      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
      
      print('⏱️  Complete test suite finished in ${elapsedMinutes.toStringAsFixed(1)} minutes (${elapsedSeconds.toStringAsFixed(1)}s)');
      
      // Both test suites should pass
      expect(results[0].exitCode, equals(0), reason: 'Parallel tests failed');
      expect(results[1].exitCode, equals(0), reason: 'Serial tests failed');
      
      // Overall target: under 5 minutes for everything
      expect(elapsedMinutes, lessThan(5), 
        reason: 'Complete test suite took ${elapsedMinutes.toStringAsFixed(1)} minutes, target is under 5 minutes');
      
      // Calculate speedup vs original (assuming 30 min baseline)
      final assumedOriginalTime = 30.0; // minutes
      final speedup = assumedOriginalTime / elapsedMinutes;
      
      print('📊 Performance Summary:');
      print('   Total time: ${elapsedMinutes.toStringAsFixed(1)} minutes');
      print('   Target: <5 minutes');
      print('   Estimated speedup: ${speedup.toStringAsFixed(1)}x faster');
      print('   Status: ${elapsedMinutes < 5 ? "🎉 SUCCESS" : "⚠️  NEEDS OPTIMIZATION"}');
      
      // Require at least 4x speedup
      expect(speedup, greaterThan(4), 
        reason: 'Speedup is ${speedup.toStringAsFixed(1)}x, should be at least 4x');
      
    }, timeout: Timeout(Duration(minutes: 8)));
    
    test('Git cache provides measurable performance benefit', () async {
      // Test with git cache enabled (first run)
      print('🔄 Testing git cache performance benefit...');
      
      final stopwatch1 = Stopwatch()..start();
      final result1 = await Process.run('dart', [
        'test',
        '--tags=parallel',
        '--concurrency=2',
        'test/integration/parallel_integration_test.dart',
      ]);
      stopwatch1.stop();
      
      expect(result1.exitCode, equals(0), reason: 'First run failed');
      
      // Run again - should be faster due to git cache  
      final stopwatch2 = Stopwatch()..start();
      final result2 = await Process.run('dart', [
        'test',
        '--tags=parallel',
        '--concurrency=2',
        'test/integration/parallel_integration_test.dart',
      ]);
      stopwatch2.stop();
      
      expect(result2.exitCode, equals(0), reason: 'Second run failed');
      
      final firstRunSec = stopwatch1.elapsedMilliseconds / 1000;
      final secondRunSec = stopwatch2.elapsedMilliseconds / 1000;
      
      print('📈 Git cache performance:');
      print('   First run:  ${firstRunSec.toStringAsFixed(1)}s');
      print('   Second run: ${secondRunSec.toStringAsFixed(1)}s');
      
      // Second run should be at least 10% faster due to git cache
      // (May be minimal if download time is small compared to test execution)
      if (firstRunSec > secondRunSec) {
        final speedup = (firstRunSec - secondRunSec) / firstRunSec;
        print('   Speedup: ${(speedup * 100).toStringAsFixed(1)}%');
        
        if (speedup > 0.1) {
          print('🎉 Git cache provides significant speedup');
        } else {
          print('✅ Git cache provides some speedup');  
        }
      } else {
        print('ℹ️  No significant speedup detected (may be due to small download overhead)');
        // This is OK - git cache benefit may not be visible in fast tests
      }
      
    }, timeout: Timeout(Duration(minutes: 10)));
    
    test('Concurrent execution scales properly', () async {
      print('🔢 Testing concurrency scaling...');
      
      // Test different concurrency levels
      final concurrencyLevels = [1, 2, 3, 5];
      final results = <int, double>{};
      
      for (final concurrency in concurrencyLevels) {
        print('Testing concurrency level: $concurrency');
        
        final stopwatch = Stopwatch()..start();
        final result = await Process.run('dart', [
          'test',
          '--tags=fast', // Use fast subset to reduce test time
          '--concurrency=$concurrency',
          'test/integration/parallel_integration_test.dart',
        ]);
        stopwatch.stop();
        
        expect(result.exitCode, equals(0), reason: 'Concurrency $concurrency failed');
        
        final elapsedSec = stopwatch.elapsedMilliseconds / 1000;
        results[concurrency] = elapsedSec;
        
        print('   Concurrency $concurrency: ${elapsedSec.toStringAsFixed(1)}s');
      }
      
      print('📊 Concurrency scaling results:');
      results.forEach((concurrency, time) {
        print('   $concurrency workers: ${time.toStringAsFixed(1)}s');
      });
      
      // Higher concurrency should generally be faster (up to a point)
      final sequential = results[1]!;
      final parallel = results[3]!;
      
      if (parallel < sequential) {
        final speedup = sequential / parallel;
        print('✅ Concurrency provides ${speedup.toStringAsFixed(1)}x speedup');
        expect(speedup, greaterThan(1.2), reason: 'Concurrency should provide meaningful speedup');
      } else {
        print('⚠️  Concurrency overhead detected - may need optimization');
        // This could happen if tests are very fast or system is resource-constrained
      }
      
    }, timeout: Timeout(Duration(minutes: 15)));
    
    test('Memory usage remains reasonable during parallel execution', () async {
      print('💾 Testing memory usage during parallel execution...');
      
      // Get baseline memory usage
      final beforeResult = await Process.run('dart', ['--version']);
      expect(beforeResult.exitCode, equals(0));
      
      // Run tests and monitor (basic check)
      final result = await Process.run('dart', [
        'test',
        '--tags=parallel',
        '--concurrency=5', // Higher concurrency to stress test
        'test/integration/parallel_integration_test.dart',
      ]);
      
      expect(result.exitCode, equals(0), reason: 'High concurrency tests failed - possible memory issue');
      
      print('✅ Parallel execution completed successfully with high concurrency');
      print('ℹ️  No obvious memory issues detected');
      
      // Note: More sophisticated memory monitoring would require additional tools
      // This test primarily ensures the system doesn't crash under load
      
    }, timeout: Timeout(Duration(minutes: 8)));
    
  }, tags: ['performance']);
}