import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

/// Isolated tests for Git clone fallback mechanism
void main() {
  group('Git Clone Fallback Mechanism', () {
    late Directory tempDir;
    late FvmContext testContext;

    setUp(() {
      // Create isolated test environment
      tempDir = Directory.systemTemp.createTempSync('fvm_git_fallback_test_');

      testContext = FvmContext.create(
        isTest: true,
        configOverrides: AppConfig(
          cachePath: p.join(tempDir.path, 'cache'),
          gitCachePath: p.join(tempDir.path, 'git_cache'),
          useGitCache: true,
        ),
      );
    });

    tearDown(() {
      // Clean up isolated test environment
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Reference error detection', () {
      test('correctly identifies reference-related errors', () {
        final service = FlutterService(testContext);

        // Test reference error patterns
        expect(
          service.isReferenceError('fatal: reference repository not found'),
          isTrue,
        );
        expect(
          service.isReferenceError('error: unable to read reference'),
          isTrue,
        );
        expect(
          service.isReferenceError('fatal: bad object in reference'),
          isTrue,
        );
        expect(
          service.isReferenceError('error: corrupt reference repository'),
          isTrue,
        );
        expect(service.isReferenceError('fatal: reference not found'), isTrue);
      });

      test('correctly ignores non-reference errors', () {
        final service = FlutterService(testContext);

        // Test non-reference error patterns
        expect(
          service.isReferenceError('fatal: repository not found'),
          isFalse,
        );
        expect(
          service.isReferenceError('fatal: remote branch not found'),
          isFalse,
        );
        expect(service.isReferenceError('error: unknown revision'), isFalse);
        expect(service.isReferenceError('fatal: ambiguous argument'), isFalse);
        expect(service.isReferenceError('fatal: network error'), isFalse);
      });
    });

    group('Isolated cache testing', () {
      test('creates isolated git cache directory', () {
        final gitCacheDir = Directory(testContext.gitCachePath);
        expect(gitCacheDir.path, contains('git_fallback_test_'));
        expect(
          gitCacheDir.path,
          isNot(equals(TestFactory.context().gitCachePath)),
        );
      });

      test('isolated context has git cache enabled', () {
        expect(testContext.gitCache, isTrue);
        expect(testContext.gitCachePath, isNotEmpty);
      });

      test('isolated context uses separate cache directory', () {
        final defaultContext = TestFactory.context();
        expect(testContext.fvmDir, isNot(equals(defaultContext.fvmDir)));
        expect(
          testContext.gitCachePath,
          isNot(equals(defaultContext.gitCachePath)),
        );
      });
    });

    group('Fallback mechanism simulation', () {
      test('can create corrupted git cache for testing', () {
        final gitCacheDir = Directory(testContext.gitCachePath);
        gitCacheDir.createSync(recursive: true);

        final corruptFile = File(p.join(gitCacheDir.path, 'corrupt_file'));
        corruptFile.writeAsStringSync('This is not a git repository');

        expect(gitCacheDir.existsSync(), isTrue);
        expect(corruptFile.existsSync(), isTrue);
        expect(
          corruptFile.readAsStringSync(),
          contains('not a git repository'),
        );
      });
    });
  });
}
