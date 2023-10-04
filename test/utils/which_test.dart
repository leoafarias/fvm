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
    print(
        'Time taken for $totalIterations iterations: ${elapsedTime.inMilliseconds}ms');
    print(
      'Time taken for 1 iteration: ${elapsedTime.inMilliseconds / totalIterations}ms',
    );
  });
}
