import 'dart:io';

import 'package:fvm/src/utils/which.dart';
import 'package:test/test.dart';

void main() {
  // Benchmark test for `which` function
  // Using a simplistic loop to measure performance.
  // For a more accurate benchmark, consider using a benchmarking package.
  test('Benchmark: which function', () {
    const totalIterations = 1000;
    // Setup specific environment variables, as above.
    var startTime = DateTime.now();
    for (int i = 0; i < totalIterations; i++) {
      which('command', binDir: false);
    }
    var endTime = DateTime.now();
    var elapsedTime = endTime.difference(startTime);

    final perInvocationSpeed = elapsedTime.inMilliseconds / totalIterations;

    // Platform-specific performance expectations
    // Windows PATH lookup is significantly slower than Unix systems
    final expectedMaxTime = Platform.isWindows ? 50.0 : 1.0;

    expect(
      perInvocationSpeed,
      lessThan(expectedMaxTime),
      reason:
          'should be faster than ${expectedMaxTime}ms per call on ${Platform.operatingSystem}',
    );
  });
}
