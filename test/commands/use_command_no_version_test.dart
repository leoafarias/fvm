import 'dart:io';

import 'package:fvm/src/models/cache_flutter_version_model.dart';
import 'package:fvm/src/models/project_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('UseCommand Error Messaging:', () {
    late TestCommandRunner runner;

    setUp(() {
      // Create a context with mock CacheService that returns empty versions
      final context = TestFactory.context(
        generators: {
          CacheService: (context) => MockCacheService(context),
        },
      );
      runner = TestCommandRunner(context);
    });

    test(
        'provides clear error message when no version arguments and no installed versions',
        () async {
      // Create a temporary directory and project structure
      final tempDir = createTempDir('use_command_no_version_test');
      createPubspecYaml(tempDir, name: 'test_project');

      // Change to the temp directory
      final originalDir = Directory.current;
      Directory.current = tempDir;

      try {
        // Execute the command - it should return a usage error exit code
        final exitCode =
            await runner.run(['fvm', 'use', '--force', '--skip-setup']);

        // Should return usage error exit code
        expect(exitCode, ExitCode.usage.code);
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
