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

    expect(perInvocationSpeed, lessThan(1), reason: 'should be faster');
  });
}
