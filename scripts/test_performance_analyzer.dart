#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';

class TestResult {
  final String name;
  final String suite;
  final int startTime;
  final int endTime;
  final String result;
  final bool hidden;

  TestResult({
    required this.name,
    required this.suite,
    required this.startTime,
    required this.endTime,
    required this.result,
    required this.hidden,
  });

  int get duration => endTime - startTime;

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      name: json['name'] ?? '',
      suite: json['suite'] ?? '',
      startTime: json['startTime'] ?? 0,
      endTime: json['endTime'] ?? 0,
      result: json['result'] ?? '',
      hidden: json['hidden'] ?? false,
    );
  }
}

class TestSuite {
  final String path;
  final List<TestResult> tests = [];
  int startTime = 0;
  int endTime = 0;

  TestSuite(this.path);

  int get duration => endTime - startTime;
  int get testCount => tests.length;
  int get visibleTestCount => tests.where((t) => !t.hidden).length;
}

class PerformanceAnalyzer {
  final Map<int, TestSuite> suites = {};
  final Map<int, Map<String, dynamic>> testStarts = {};
  int totalStartTime = 0;
  int totalEndTime = 0;

  void processJsonLine(String line) {
    try {
      final json = jsonDecode(line);
      final type = json['type'];
      final time = json['time'] ?? 0;

      switch (type) {
        case 'start':
          totalStartTime = time;
          break;
        case 'suite':
          final suiteId = json['suite']['id'];
          final path = json['suite']['path'];
          suites[suiteId] = TestSuite(path);
          break;
        case 'testStart':
          final testId = json['test']['id'];
          final suiteId = json['test']['suiteID'];
          final name = json['test']['name'];
          testStarts[testId] = {
            'name': name,
            'suiteId': suiteId,
            'startTime': time,
          };
          break;
        case 'testDone':
          final testId = json['testID'];
          final result = json['result'];
          final hidden = json['hidden'] ?? false;
          
          if (testStarts.containsKey(testId)) {
            final testStart = testStarts[testId]!;
            final suiteId = testStart['suiteId'];
            
            if (suites.containsKey(suiteId)) {
              final suite = suites[suiteId]!;
              final testResult = TestResult(
                name: testStart['name'],
                suite: suite.path,
                startTime: testStart['startTime'],
                endTime: time,
                result: result,
                hidden: hidden,
              );
              suite.tests.add(testResult);
              
              // Update suite timing
              if (suite.startTime == 0 || testStart['startTime'] < suite.startTime) {
                suite.startTime = testStart['startTime'];
              }
              if (time > suite.endTime) {
                suite.endTime = time;
              }
            }
            testStarts.remove(testId);
          }
          break;
        case 'done':
          totalEndTime = time;
          break;
      }
    } catch (e) {
      // Skip malformed JSON lines
    }
  }

  void generateReport() {
    final allTests = <TestResult>[];
    for (final suite in suites.values) {
      allTests.addAll(suite.tests.where((t) => !t.hidden));
    }

    // Sort tests by duration (slowest first)
    allTests.sort((a, b) => b.duration.compareTo(a.duration));

    // Sort suites by duration (slowest first)
    final sortedSuites = suites.values.toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));

    print('# FVM Test Suite Performance Report');
    print('Generated on: ${DateTime.now()}');
    print('');

    // Overall statistics
    final totalDuration = totalEndTime - totalStartTime;
    final totalTestCount = allTests.length;
    final avgTestDuration = totalTestCount > 0 ? totalDuration / totalTestCount : 0;

    print('## Overall Statistics');
    print('- **Total test suite duration**: ${formatDuration(totalDuration)}');
    print('- **Total tests executed**: $totalTestCount');
    print('- **Average test duration**: ${formatDuration(avgTestDuration.round())}');
    print('- **Test suites**: ${suites.length}');
    print('');

    // Slowest tests
    print('## Slowest Individual Tests (Top 20)');
    print('| Rank | Test Name | Suite | Duration | Status |');
    print('|------|-----------|-------|----------|--------|');
    
    for (int i = 0; i < min(20, allTests.length); i++) {
      final test = allTests[i];
      final suiteName = test.suite.split('/').last.replaceAll('_test.dart', '');
      final testName = test.name.length > 50 
          ? '${test.name.substring(0, 47)}...' 
          : test.name;
      print('| ${i + 1} | $testName | $suiteName | ${formatDuration(test.duration)} | ${test.result} |');
    }
    print('');

    // Slowest test suites
    print('## Slowest Test Suites');
    print('| Rank | Suite | Tests | Duration | Avg per Test |');
    print('|------|-------|-------|----------|--------------|');
    
    for (int i = 0; i < sortedSuites.length; i++) {
      final suite = sortedSuites[i];
      final suiteName = suite.path.split('/').last.replaceAll('_test.dart', '');
      final avgPerTest = suite.visibleTestCount > 0 
          ? suite.duration / suite.visibleTestCount 
          : 0;
      print('| ${i + 1} | $suiteName | ${suite.visibleTestCount} | ${formatDuration(suite.duration)} | ${formatDuration(avgPerTest.round())} |');
    }
    print('');

    // Performance insights
    print('## Performance Insights');
    
    // Find tests that take significantly longer than average
    final slowTests = allTests.where((t) => t.duration > avgTestDuration * 3).toList();
    if (slowTests.isNotEmpty) {
      print('### Tests Taking 3x Longer Than Average');
      for (final test in slowTests.take(10)) {
        final suiteName = test.suite.split('/').last.replaceAll('_test.dart', '');
        print('- **$suiteName**: ${test.name} (${formatDuration(test.duration)})');
      }
      print('');
    }

    // Find suites with high variance in test duration
    print('### Test Suites with High Duration Variance');
    for (final suite in sortedSuites.take(5)) {
      final visibleTests = suite.tests.where((t) => !t.hidden).toList();
      if (visibleTests.length > 1) {
        final durations = visibleTests.map((t) => t.duration).toList();
        final mean = durations.reduce((a, b) => a + b) / durations.length;
        final variance = durations.map((d) => pow(d - mean, 2)).reduce((a, b) => a + b) / durations.length;
        final stdDev = sqrt(variance);
        final coefficientOfVariation = stdDev / mean;
        
        if (coefficientOfVariation > 1.0) {
          final suiteName = suite.path.split('/').last.replaceAll('_test.dart', '');
          print('- **$suiteName**: High variance (CV: ${(coefficientOfVariation * 100).toStringAsFixed(1)}%)');
        }
      }
    }
    print('');

    // Optimization recommendations
    print('## Optimization Recommendations');
    print('');
    print('### Quick Wins');
    
    // Tests that are significantly slower than others in the same suite
    for (final suite in sortedSuites.take(5)) {
      final visibleTests = suite.tests.where((t) => !t.hidden).toList();
      if (visibleTests.length > 2) {
        visibleTests.sort((a, b) => b.duration.compareTo(a.duration));
        final slowest = visibleTests.first;
        final median = visibleTests[visibleTests.length ~/ 2];
        
        if (slowest.duration > median.duration * 5) {
          final suiteName = suite.path.split('/').last.replaceAll('_test.dart', '');
          print('- **$suiteName**: "${slowest.name}" takes ${formatDuration(slowest.duration)}, much slower than median ${formatDuration(median.duration)}');
        }
      }
    }
    
    print('');
    print('### General Recommendations');
    print('- Consider parallelizing slow integration tests');
    print('- Review tests that perform actual Flutter SDK operations');
    print('- Mock external dependencies and file system operations where possible');
    print('- Consider splitting large test suites into smaller, focused ones');
    print('- Use `setUp` and `tearDown` efficiently to avoid repeated initialization');
  }

  String formatDuration(int milliseconds) {
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    } else if (milliseconds < 60000) {
      return '${(milliseconds / 1000).toStringAsFixed(1)}s';
    } else {
      final minutes = milliseconds ~/ 60000;
      final seconds = (milliseconds % 60000) / 1000;
      return '${minutes}m ${seconds.toStringAsFixed(1)}s';
    }
  }
}

Future<void> main(List<String> args) async {
  final analyzer = PerformanceAnalyzer();
  
  print('Running tests with performance analysis...');
  
  // Run tests with JSON reporter
  final process = await Process.start(
    'dart',
    ['test', '--reporter=json'],
    workingDirectory: Directory.current.path,
  );

  // Process output line by line
  await for (final line in process.stdout.transform(utf8.decoder).transform(LineSplitter())) {
    analyzer.processJsonLine(line);
  }

  // Wait for process to complete
  final exitCode = await process.exitCode;
  
  if (exitCode != 0) {
    print('Tests completed with exit code: $exitCode');
  }

  // Generate and display the report
  analyzer.generateReport();
}
