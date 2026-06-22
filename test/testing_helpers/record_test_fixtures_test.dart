import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../tool/record_test_fixtures.dart' as recorder;
import '../testing_utils.dart';

void main() {
  setUp(() {
    exitCode = 0;
  });

  tearDown(() {
    exitCode = 0;
  });

  group('record_test_fixtures flutter-version', () {
    test('writes loader-required fixture metadata', () async {
      final flutterRoot = createTempDir('flutter_root_');
      File(p.join(flutterRoot.path, 'version'))
        ..createSync(recursive: true)
        ..writeAsStringSync('3.10.0\n');
      File(p.join(flutterRoot.path, 'bin', 'cache', 'flutter.version.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({
            'channel': 'stable',
            'dartSdkVersion': '3.0.0 (build 3.0.0-0.0.dev)',
            'flutterVersion': '3.10.5',
            'frameworkVersion': '3.10.5',
            'repositoryUrl': 'https://github.com/flutter/flutter.git',
          }),
        );
      final outputDir = createTempDir('recorded_fixtures_');

      await recorder.main([
        'flutter-version',
        '--flutter-root',
        flutterRoot.path,
        '--name',
        'stable_3_10_0',
        '--output',
        outputDir.path,
      ]);

      expect(exitCode, equals(0));
      final outputFile = File(p.join(outputDir.path, 'stable_3_10_0.json'));
      final payload = jsonDecode(outputFile.readAsStringSync()) as Map;

      expect(payload['name'], equals('stable_3_10_0'));
      expect(payload['legacyVersion'], equals('3.10.0'));
      expect(payload['dartSdkVersion'], equals('3.0.0 (build 3.0.0-0.0.dev)'));
      expect(
        payload['flutterVersionJson'],
        containsPair('flutterVersion', '3.10.5'),
      );
    });

    test(
      'emits empty flutterVersionJson when JSON metadata is absent',
      () async {
        final flutterRoot = createTempDir('flutter_root_');
        File(p.join(flutterRoot.path, 'version'))
          ..createSync(recursive: true)
          ..writeAsStringSync('3.7.12\n');
        File(p.join(flutterRoot.path, 'bin', 'cache', 'dart-sdk', 'version'))
          ..createSync(recursive: true)
          ..writeAsStringSync('2.19.6\n');
        final outputDir = createTempDir('recorded_fixtures_');

        await recorder.main([
          'flutter-version',
          '--flutter-root',
          flutterRoot.path,
          '--name',
          'stable_3_7_12',
          '--output',
          outputDir.path,
        ]);

        expect(exitCode, equals(0));
        final outputFile = File(p.join(outputDir.path, 'stable_3_7_12.json'));
        final payload = jsonDecode(outputFile.readAsStringSync()) as Map;

        expect(payload['legacyVersion'], equals('3.7.12'));
        expect(payload['dartSdkVersion'], equals('2.19.6'));
        expect(payload['flutterVersionJson'], isEmpty);
      },
    );

    test(
      'does not write a partial fixture when Dart SDK metadata is missing',
      () async {
        final flutterRoot = createTempDir('flutter_root_');
        File(p.join(flutterRoot.path, 'version'))
          ..createSync(recursive: true)
          ..writeAsStringSync('3.10.0\n');
        final outputDir = createTempDir('recorded_fixtures_');

        await recorder.main([
          'flutter-version',
          '--flutter-root',
          flutterRoot.path,
          '--name',
          'missing_dart_sdk',
          '--output',
          outputDir.path,
        ]);

        expect(exitCode, equals(66));
        expect(
          File(p.join(outputDir.path, 'missing_dart_sdk.json')).existsSync(),
          isFalse,
        );
      },
    );
  });
}
