import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('UseCommand Error Messaging:', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    test(
        'provides clear error message when no version arguments and no installed versions',
        () async {
      // Get a reference to the original services
      final services = runner.services;

      // Create a temporary directory and project structure
      final tempDir = createTempDir('use_command_no_version_test');
      createPubspecYaml(tempDir, name: 'test_project');

      // Change to the temp directory
      final originalDir = Directory.current;
      Directory.current = tempDir;

      // Ensure no versions are installed in cache
      final mockFlutterService =
          services.get<FlutterService>() as MockFlutterService;
      mockFlutterService.clearInstalledVersions();

      try {
        // Execute the command - it should throw a UsageException with our error message
        expect(
          () => runner.run(['fvm', 'use', '--force', '--skip-setup']),
          throwsA(
            predicate((e) =>
                e is UsageException &&
                e.message.contains(
                    'No version specified and no versions are installed') &&
                e.message
                    .contains('Please specify a version: fvm use <version>') &&
                e.message.contains(
                    'Or install a version first: fvm install <version>')),
          ),
        );
      } finally {
        // Restore original directory
        Directory.current = originalDir;
        // Clean up
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}

/// Mock CacheService for testing
class MockCacheService extends CacheService {
  MockCacheService(super.context);

  @override
  Future<List<CacheFlutterVersion>> getAllVersions() async {
    // Return empty list to simulate no installed versions
    return [];
  }
}

/// Mock ProjectService for testing
class MockProjectService extends ProjectService {
  final Project _mockProject;

  MockProjectService(super.context, this._mockProject);

  @override
  Project findAncestor({Directory? directory}) {
    return _mockProject;
  }
}
