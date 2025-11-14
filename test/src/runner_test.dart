import 'dart:async';
import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/utils/constants.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/version.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../testing_utils.dart';

class MockPubUpdater extends Mock implements PubUpdater {}

void main() {
  late MockPubUpdater mockPubUpdater;
  late FvmCommandRunner runner;
  late FvmContext testContext;
  late LocalAppConfig originalConfig;

  setUp(() {
    // Save original config to restore later
    originalConfig = LocalAppConfig.read();

    mockPubUpdater = MockPubUpdater();
    testContext = TestFactory.context();
    runner = FvmCommandRunner(testContext, pubUpdater: mockPubUpdater);
  });

  tearDown(() {
    // Restore original config
    originalConfig.save();
  });

  group('Update Check Logic', () {
    test('performs check on first run (null timestamp)', () async {
      // Setup: Clear timestamp to simulate first run
      final config = LocalAppConfig.read()
        ..lastUpdateCheck = null
        ..disableUpdateCheck = false
        ..save();

      // Mock isUpToDate to return false (update available)
      when(() => mockPubUpdater.isUpToDate(
            packageName: any(named: 'packageName'),
            currentVersion: any(named: 'currentVersion'),
          )).thenAnswer((_) async => false);

      when(() => mockPubUpdater.getLatestVersion(any()))
          .thenAnswer((_) async => '999.0.0');

      // Act: Run a simple command
      await runner.run(['--version']);

      // Verify: Check was executed
      verify(() => mockPubUpdater.isUpToDate(
            packageName: kPackageName,
            currentVersion: packageVersion,
          )).called(1);

      // Verify: Timestamp was written
      final updatedConfig = LocalAppConfig.read();
      expect(updatedConfig.lastUpdateCheck, isNotNull);
      expect(
        updatedConfig.lastUpdateCheck!.isAfter(
          DateTime.now().subtract(const Duration(seconds: 5)),
        ),
        isTrue,
      );
    });

    test('skips check when within 24 hours', () async {
      // Setup: Set recent timestamp (1 hour ago)
      final recentTime = DateTime.now().subtract(const Duration(hours: 1));
      LocalAppConfig.read()
        ..lastUpdateCheck = recentTime
        ..disableUpdateCheck = false
        ..save();

      // Recreate context to pick up the new config
      final context = TestFactory.context();
      final testRunner = FvmCommandRunner(context, pubUpdater: mockPubUpdater);

      // Act: Run a simple command
      await testRunner.run(['--version']);

      // Verify: Check was NOT executed
      verifyNever(() => mockPubUpdater.isUpToDate(
            packageName: any(named: 'packageName'),
            currentVersion: any(named: 'currentVersion'),
          ));
    });

    test('performs check after 24 hours', () async {
      // Setup: Set old timestamp (25 hours ago)
      final oldTime = DateTime.now().subtract(const Duration(hours: 25));
      LocalAppConfig.read()
        ..lastUpdateCheck = oldTime
        ..disableUpdateCheck = false
        ..save();

      // Mock isUpToDate to return true (no update)
      when(() => mockPubUpdater.isUpToDate(
            packageName: any(named: 'packageName'),
            currentVersion: any(named: 'currentVersion'),
          )).thenAnswer((_) async => true);

      // Recreate context to pick up the new config
      final context = TestFactory.context();
      final testRunner = FvmCommandRunner(context, pubUpdater: mockPubUpdater);

      // Act: Run a simple command
      await testRunner.run(['--version']);

      // Verify: Check was executed
      verify(() => mockPubUpdater.isUpToDate(
            packageName: kPackageName,
            currentVersion: packageVersion,
          )).called(1);

      // Verify: Timestamp was updated
      final updatedConfig = LocalAppConfig.read();
      expect(updatedConfig.lastUpdateCheck, isNotNull);
      expect(
        updatedConfig.lastUpdateCheck!.isAfter(oldTime),
        isTrue,
      );
    });

    test('skips check when disabled', () async {
      // Setup: Set disableUpdateCheck = true
      LocalAppConfig.read()
        ..lastUpdateCheck = null // Even with null timestamp
        ..disableUpdateCheck = true
        ..save();

      // Recreate context to pick up the new config
      final context = TestFactory.context();
      final testRunner = FvmCommandRunner(context, pubUpdater: mockPubUpdater);

      // Act: Run a simple command
      await testRunner.run(['--version']);

      // Verify: Check was NOT executed
      verifyNever(() => mockPubUpdater.isUpToDate(
            packageName: any(named: 'packageName'),
            currentVersion: any(named: 'currentVersion'),
          ));
    });

    test('handles timeout gracefully', () async {
      // Setup: Mock delayed response that times out
      LocalAppConfig.read()
        ..lastUpdateCheck = null
        ..disableUpdateCheck = false
        ..save();

      when(() => mockPubUpdater.isUpToDate(
            packageName: any(named: 'packageName'),
            currentVersion: any(named: 'currentVersion'),
          )).thenAnswer(
        (_) async {
          // Simulate a very long delay
          await Future.delayed(const Duration(seconds: 10));
          return true;
        },
      );

      // Recreate context to pick up the new config
      final context = TestFactory.context();
      final testRunner = FvmCommandRunner(context, pubUpdater: mockPubUpdater);

      // Act: Run command (should not hang)
      final exitCode = await testRunner.run(['--version']);

      // Verify: Command completed successfully despite timeout
      expect(exitCode, equals(0));
    });

    test('handles network errors gracefully', () async {
      // Setup: Mock network failure
      LocalAppConfig.read()
        ..lastUpdateCheck = null
        ..disableUpdateCheck = false
        ..save();

      when(() => mockPubUpdater.isUpToDate(
            packageName: any(named: 'packageName'),
            currentVersion: any(named: 'currentVersion'),
          )).thenThrow(
        const SocketException('Network unreachable'),
      );

      // Recreate context to pick up the new config
      final context = TestFactory.context();
      final testRunner = FvmCommandRunner(context, pubUpdater: mockPubUpdater);

      // Act: Run command
      final exitCode = await testRunner.run(['--version']);

      // Verify: Command completed successfully despite error
      expect(exitCode, equals(0));

      // Verify: Timestamp was NOT written on error (retry next run)
      final updatedConfig = LocalAppConfig.read();
      expect(updatedConfig.lastUpdateCheck, isNull);
    });

    test('records timestamp only on successful check', () async {
      // Setup: Clear timestamp
      LocalAppConfig.read()
        ..lastUpdateCheck = null
        ..disableUpdateCheck = false
        ..save();

      // Mock successful response
      when(() => mockPubUpdater.isUpToDate(
            packageName: any(named: 'packageName'),
            currentVersion: any(named: 'currentVersion'),
          )).thenAnswer((_) async => true);

      // Recreate context to pick up the new config
      final context = TestFactory.context();
      final testRunner = FvmCommandRunner(context, pubUpdater: mockPubUpdater);

      // Act: Run command
      await testRunner.run(['--version']);

      // Verify: Timestamp was written after successful check
      final updatedConfig = LocalAppConfig.read();
      expect(updatedConfig.lastUpdateCheck, isNotNull);
      expect(
        updatedConfig.lastUpdateCheck!.isAfter(
          DateTime.now().subtract(const Duration(seconds: 5)),
        ),
        isTrue,
      );
    });

    test('displays update message when available', () async {
      // Setup: Clear timestamp
      LocalAppConfig.read()
        ..lastUpdateCheck = null
        ..disableUpdateCheck = false
        ..save();

      // Mock version mismatch (update available)
      when(() => mockPubUpdater.isUpToDate(
            packageName: any(named: 'packageName'),
            currentVersion: any(named: 'currentVersion'),
          )).thenAnswer((_) async => false);

      when(() => mockPubUpdater.getLatestVersion(kPackageName))
          .thenAnswer((_) async => '999.0.0');

      // Recreate context to pick up the new config
      final context = TestFactory.context();
      final testRunner = FvmCommandRunner(context, pubUpdater: mockPubUpdater);

      // Act: Run command and capture output
      final output = <String>[];
      await runZoned(
        () async => await testRunner.run(['--version']),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            output.add(line);
          },
        ),
      );

      // Verify: Update message was displayed
      // The actual output will be through logger, but we can verify the calls
      verify(() => mockPubUpdater.isUpToDate(
            packageName: kPackageName,
            currentVersion: packageVersion,
          )).called(1);

      verify(() => mockPubUpdater.getLatestVersion(kPackageName)).called(1);
    });
  });

  group('Update Check with Config Command', () {
    test('skips update check for config command itself', () async {
      // This ensures config changes don't trigger update checks
      LocalAppConfig.read()
        ..lastUpdateCheck = null
        ..disableUpdateCheck = false
        ..save();

      // Recreate context to pick up the new config
      final context = TestFactory.context();
      final testRunner = FvmCommandRunner(context, pubUpdater: mockPubUpdater);

      // Act: Run config command to view settings
      await testRunner.run(['config']);

      // Verify update check was not executed
      verifyNever(() => mockPubUpdater.isUpToDate(
        packageName: any(named: 'packageName'),
        currentVersion: any(named: 'currentVersion'),
      ));
    });
  });
}
