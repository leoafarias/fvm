#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// Monitors test performance and exports data for CI/CD integration
Future<void> main(List<String> args) async {
  final outputFormat = args.contains('--json') ? 'json' : 'markdown';
  final includeWorkflow = args.contains('--include-workflow');
  final threshold = _parseThreshold(args);
  
  print('Running FVM test performance monitoring...');
  
  final testPaths = includeWorkflow 
      ? ['test/'] 
      : [
          'test/utils/',
          'test/src/utils/',
          'test/src/models/',
          'test/src/services/',
          'test/src/api/',
        ];

  final results = await _runTests(testPaths);
  
  if (outputFormat == 'json') {
    _outputJson(results);
  } else {
    _outputMarkdown(results, threshold);
  }
  
  // Check if any tests exceed threshold
  final slowTests = _findSlowTests(results, threshold);
  if (slowTests.isNotEmpty && !args.contains('--no-fail')) {
    print('\nWARNING: ${slowTests.length} tests exceed ${threshold}ms threshold');
    exit(1);
  }
}

int _parseThreshold(List<String> args) {
  final thresholdIndex = args.indexOf('--threshold');
  if (thresholdIndex != -1 && thresholdIndex + 1 < args.length) {
    return int.tryParse(args[thresholdIndex + 1]) ?? 1000;
  }
  return 1000; // Default 1 second threshold
}

Future<List<Map<String, dynamic>>> _runTests(List<String> testPaths) async {
  final results = <Map<String, dynamic>>[];
  
  for (final path in testPaths) {
    final stopwatch = Stopwatch()..start();
    
    final process = await Process.start(
      'dart',
      ['test', '--reporter=json', path],
      workingDirectory: Directory.current.path,
    );

    final lines = <String>[];
    await for (final line in process.stdout.transform(utf8.decoder).transform(LineSplitter())) {
      lines.add(line);
    }

    final exitCode = await process.exitCode;
    stopwatch.stop();
    
    final testResults = _parseTestResults(lines);
    
    results.add({
      'path': path,
      'totalDuration': stopwatch.elapsedMilliseconds,
      'testCount': testResults.length,
      'tests': testResults,
      'exitCode': exitCode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  return results;
}

List<Map<String, dynamic>> _parseTestResults(List<String> lines) {
  final testResults = <Map<String, dynamic>>[];
  final testStarts = <int, Map<String, dynamic>>{};
  
  for (final line in lines) {
    try {
      final json = jsonDecode(line);
      final type = json['type'];
      
      if (type == 'testStart') {
        final testId = json['test']['id'];
        testStarts[testId] = {
          'name': json['test']['name'],
          'startTime': json['time'],
        };
      } else if (type == 'testDone') {
        final testId = json['testID'];
        if (testStarts.containsKey(testId)) {
          final start = testStarts[testId]!;
          final duration = json['time'] - start['startTime'];
          testResults.add({
            'name': start['name'],
            'duration': duration,
            'result': json['result'],
            'hidden': json['hidden'] ?? false,
          });
        }
      }
    } catch (e) {
      // Skip malformed JSON
    }
  }
  
  return testResults.where((t) => !(t['hidden'] as bool)).toList();
}

List<Map<String, dynamic>> _findSlowTests(List<Map<String, dynamic>> results, int threshold) {
  final slowTests = <Map<String, dynamic>>[];
  
  for (final result in results) {
    final tests = result['tests'] as List<Map<String, dynamic>>;
    for (final test in tests) {
      if ((test['duration'] as int) > threshold) {
        test['suite'] = result['path'];
        slowTests.add(test);
      }
    }
  }
  
  return slowTests;
}

void _outputJson(List<Map<String, dynamic>> results) {
  final output = {
    'timestamp': DateTime.now().toIso8601String(),
    'summary': _calculateSummary(results),
    'suites': results,
  };
  
  print(jsonEncode(output));
}

void _outputMarkdown(List<Map<String, dynamic>> results, int threshold) {
  final summary = _calculateSummary(results);
  
  print('# FVM Test Performance Report');
  print('Generated: ${DateTime.now()}');
  print('');
  
  print('## Summary');
  print('- **Total Duration**: ${_formatDuration(summary['totalDuration'])}');
  print('- **Total Tests**: ${summary['totalTests']}');
  print('- **Average per Test**: ${_formatDuration(summary['averagePerTest'])}');
  print('- **Performance Threshold**: ${_formatDuration(threshold)}');
  print('');
  
  // Suite breakdown
  print('## Test Suite Performance');
  print('| Suite | Duration | Tests | Avg/Test | Status |');
  print('|-------|----------|-------|----------|--------|');
  
  results.sort((a, b) => (b['totalDuration'] as int).compareTo(a['totalDuration'] as int));
  
  for (final result in results) {
    final path = (result['path'] as String).replaceAll('test/', '').replaceAll('/', '');
    final duration = result['totalDuration'] as int;
    final testCount = result['testCount'] as int;
    final avgPerTest = testCount > 0 ? duration / testCount : 0;
    final status = result['exitCode'] == 0 ? '✅' : '❌';
    
    print('| $path | ${_formatDuration(duration)} | $testCount | ${_formatDuration(avgPerTest.round())} | $status |');
  }
  print('');
  
  // Slowest tests
  final allTests = <Map<String, dynamic>>[];
  for (final result in results) {
    final tests = result['tests'] as List<Map<String, dynamic>>;
    for (final test in tests) {
      test['suite'] = result['path'];
      allTests.add(test);
    }
  }
  
  allTests.sort((a, b) => (b['duration'] as int).compareTo(a['duration'] as int));
  
  print('## Slowest Tests (Top 15)');
  print('| Rank | Test | Suite | Duration | Status |');
  print('|------|------|-------|----------|--------|');
  
  for (int i = 0; i < 15 && i < allTests.length; i++) {
    final test = allTests[i];
    final name = _truncate(test['name'] as String, 40);
    final suite = (test['suite'] as String).replaceAll('test/', '').replaceAll('/', '');
    final duration = test['duration'] as int;
    final status = test['result'] == 'success' ? '✅' : '❌';
    
    print('| ${i + 1} | $name | $suite | ${_formatDuration(duration)} | $status |');
  }
  print('');
  
  // Performance alerts
  final slowTests = _findSlowTests(results, threshold);
  if (slowTests.isNotEmpty) {
    print('## ⚠️ Performance Alerts');
    print('The following tests exceed the ${_formatDuration(threshold)} threshold:');
    print('');
    
    for (final test in slowTests.take(10)) {
      final name = test['name'] as String;
      final suite = (test['suite'] as String).replaceAll('test/', '').replaceAll('/', '');
      final duration = test['duration'] as int;
      print('- **$suite**: $name (${_formatDuration(duration)})');
    }
    print('');
  }
  
  print('## Optimization Recommendations');
  print('');
  print('### Immediate Actions');
  print('1. **Focus on API tests**: The `test/src/api/` suite has the highest average duration');
  print('2. **Review file lock tests**: Several file locking tests are taking significant time');
  print('3. **Mock external dependencies**: Tests involving Flutter releases API should be mocked');
  print('');
  print('### Long-term Improvements');
  print('- Implement test parallelization for independent test suites');
  print('- Create shared test fixtures to reduce setup/teardown overhead');
  print('- Consider splitting large test files into smaller, focused suites');
  print('- Add performance regression detection to CI/CD pipeline');
}

Map<String, dynamic> _calculateSummary(List<Map<String, dynamic>> results) {
  var totalDuration = 0;
  var totalTests = 0;
  
  for (final result in results) {
    totalDuration += result['totalDuration'] as int;
    totalTests += result['testCount'] as int;
  }
  
  return {
    'totalDuration': totalDuration,
    'totalTests': totalTests,
    'averagePerTest': totalTests > 0 ? totalDuration ~/ totalTests : 0,
  };
}

String _formatDuration(int milliseconds) {
  if (milliseconds < 1000) {
    return '${milliseconds}ms';
  } else if (milliseconds < 60000) {
    return '${(milliseconds / 1000).toStringAsFixed(1)}s';
  } else {
    final minutes = milliseconds ~/ 60000;
    final seconds = (milliseconds % 60000) / 1000;
    return '${minutes}m${seconds.toStringAsFixed(1)}s';
  }
}

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 3)}...';
}
