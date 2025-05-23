import 'dart:io';

import 'package:fvm/src/models/project_model.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late TestCommandRunner runner;
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = createTempDir('use_command_integration_test');

    // Create a basic Flutter project structure
    createPubspecYaml(tempDirectory,
        name: 'test_project', sdkConstraint: '>=2.17.0 <4.0.0');

    // Create a test FVM context with the default mock services
    final testContext = TestFactory.context(
      debugLabel: 'use_command_integration_test',
      workingDirectoryOverride: tempDirectory.path,
    );

    runner = TestCommandRunner(testContext);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  /// This is the main integration test that exercises the full workflow of the use command
  /// It goes through a series of operations to test the complete functionality
  test('Full end-to-end use command workflow', () async {
    // Step 1: Use a stable channel version
    var exitCode = await runner.run([
      'fvm',
      'use',
      'stable',
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify project was configured
    var project = Project.loadFromDirectory(tempDirectory);
    expect(project.hasConfig, isTrue);
    expect(project.pinnedVersion?.name, 'stable');
    expect(project.pinnedVersion?.isChannel, isTrue);

    // Verify symlinks were created
    var fvmDir = Directory(p.join(tempDirectory.path, '.fvm'));
    expect(fvmDir.existsSync(), isTrue);

    var flutterSdkLink = File(p.join(fvmDir.path, 'flutter_sdk'));
    expect(flutterSdkLink.existsSync(), isTrue);

    // Step 2: Switch to a release version
    exitCode = await runner.run([
      'fvm',
      'use',
      '3.10.0',
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify project configuration was updated
    project = Project.loadFromDirectory(tempDirectory);
    expect(project.pinnedVersion?.name, '3.10.0');
    expect(project.pinnedVersion?.isRelease, isTrue);

    // Step 3: Add a flavor
    exitCode = await runner.run([
      'fvm',
      'use',
      'beta',
      '--flavor',
      'dev',
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify flavor was added but main version is still the same
    project = Project.loadFromDirectory(tempDirectory);
    expect(project.pinnedVersion?.name, '3.10.0'); // Main version unchanged
    expect(project.flavors.length, 1);
    expect(project.flavors['dev'], 'beta');

    // Step 4: Switch to the flavor
    exitCode = await runner.run([
      'fvm',
      'use',
      'dev', // Using the flavor name
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify we've switched to the flavor's version
    project = Project.loadFromDirectory(tempDirectory);
    expect(project.pinnedVersion?.name, 'beta');

    // Step 5: Add another flavor and switch to it
    exitCode = await runner.run([
      'fvm',
      'use',
      '2.10.0',
      '--flavor',
      'legacy',
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify flavor was added but main version is still beta
    project = Project.loadFromDirectory(tempDirectory);
    expect(project.pinnedVersion?.name, 'beta'); // Main version unchanged
    expect(project.flavors.length, 2);
    expect(project.flavors['legacy'], '2.10.0');

    exitCode = await runner.run([
      'fvm',
      'use',
      'legacy', // Using the flavor name
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify we've switched to the flavor's version
    project = Project.loadFromDirectory(tempDirectory);
    expect(project.pinnedVersion?.name, '2.10.0');

    // Step 6: Go back to the original version with force flag
    exitCode = await runner.run([
      'fvm',
      'use',
      '3.10.0',
      '--force',
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify we're back to the original version
    project = Project.loadFromDirectory(tempDirectory);
    expect(project.pinnedVersion?.name, '3.10.0');

    // Step 7: Use a Git commit reference
    exitCode = await runner.run([
      'fvm',
      'use',
      'abcdef1234567890', // Mock Git hash
      '--skip-setup', // Skip setup for test speed
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify we've switched to the commit reference
    project = Project.loadFromDirectory(tempDirectory);
    expect(project.pinnedVersion?.name, 'abcdef1234567890');
    expect(project.pinnedVersion?.isCommit, isTrue);

    // Step 8: Update a flavor
    exitCode = await runner.run([
      'fvm',
      'use',
      'stable',
      '--flavor',
      'dev', // This flavor already exists with 'beta'
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify the flavor was updated
    project = Project.loadFromDirectory(tempDirectory);
    expect(project.pinnedVersion?.name,
        'abcdef1234567890'); // Main version unchanged
    expect(project.flavors['dev'], 'stable'); // Updated from 'beta'

    // Step 9: Verify .gitignore and VS Code settings
    final gitignoreFile = File(p.join(tempDirectory.path, '.gitignore'));
    if (gitignoreFile.existsSync()) {
      final content = gitignoreFile.readAsStringSync();
      expect(content.contains('.fvm/flutter_sdk'), isTrue);
    }

    final vscodeDir = Directory(p.join(tempDirectory.path, '.vscode'));
    if (vscodeDir.existsSync()) {
      final settingsFile = File(p.join(vscodeDir.path, 'settings.json'));
      if (settingsFile.existsSync()) {
        final content = settingsFile.readAsStringSync();
        expect(content.contains('flutter.sdkPath'), isTrue);
      }
    }
  });

  test('Handles dependencies workflow correctly', () async {
    // First set up a version
    var exitCode = await runner.run([
      'fvm',
      'use',
      'stable',
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify dependencies resolution with --skip-pub-get
    exitCode = await runner.run([
      'fvm',
      'use',
      'beta',
      '--skip-pub-get',
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify with normal pub get
    exitCode = await runner.run([
      'fvm',
      'use',
      'stable',
    ]);

    expect(exitCode, ExitCode.success.code);
  });

  test('Honors SDK constraints', () async {
    // Create a pubspec with a strict SDK constraint
    createPubspecYaml(tempDirectory,
        name: 'test_project', sdkConstraint: '>=2.17.0 <3.0.0');

    // Try to use a version that violates the constraint - should warn but succeed with force
    var exitCode = await runner.run([
      'fvm',
      'use',
      '3.10.0',
      '--force',
    ]);

    expect(exitCode, ExitCode.success.code);

    // Verify the version was set despite the constraint
    var project = Project.loadFromDirectory(tempDirectory);
    expect(project.pinnedVersion?.name, '3.10.0');
  });
}
