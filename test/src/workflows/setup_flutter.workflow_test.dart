import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/setup_flutter.workflow.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

class InterruptedSetupFlutterService extends FlutterService {
  InterruptedSetupFlutterService(super.context);

  @override
  Future<ProcessResult> setup(CacheFlutterVersion version) async {
    throw const ForceExit('', 130);
  }
}

void main() {
  test('propagates interruption without logging setup failure', () async {
    final tempDirs = TempDirectoryTracker();
    addTearDown(tempDirs.cleanUp);

    final context = TestFactory.context(
      generators: {
        FlutterService: (context) => InterruptedSetupFlutterService(context),
      },
    );
    final version = CacheFlutterVersion.fromVersion(
      FlutterVersion.parse('3.10.0'),
      directory: tempDirs.create().path,
    );

    await expectLater(
      () => SetupFlutterWorkflow(context)(version),
      throwsA(
        isA<ForceExit>().having(
          (error) => error.exitCode,
          'exitCode',
          130,
        ),
      ),
    );

    final logger = context.get<Logger>();
    expect(
      logger.outputs.any(
        (message) => message.contains('Failed to setup Flutter SDK'),
      ),
      isFalse,
    );
    expect(
      logger.outputs.any((message) => message.contains('is setup')),
      isFalse,
    );
  });
}
