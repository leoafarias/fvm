import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Install Script Improvements:', () {
    late File installScript;

    setUpAll(() {
      installScript = File('scripts/install.sh');
      expect(installScript.existsSync(), true,
          reason: 'Install script should exist');
    });

    test('Script passes shellcheck validation', () async {
      // Run shellcheck on the install script
      final result = await Process.run('shellcheck', ['scripts/install.sh']);
      
      expect(result.exitCode, equals(0),
          reason: 'Shellcheck should pass without errors. Output: ${result.stdout}\nErrors: ${result.stderr}');
    });

    test('Script has proper bash syntax', () async {
      // Test bash syntax validation
      final result = await Process.run('bash', ['-n', 'scripts/install.sh']);
      
      expect(result.exitCode, equals(0),
          reason: 'Script should have valid bash syntax. Errors: ${result.stderr}');
    });

    test('Script contains security improvements', () async {
      final content = await installScript.readAsString();
      
      // Check for input validation
      expect(content.contains('Invalid version format'), true,
          reason: 'Script should validate version input format');
      
      // Check for download validation
      expect(content.contains('--fail --show-error'), true,
          reason: 'Script should use curl with proper error handling');
      
      // Check for file validation
      expect(content.contains('file fvm.tar.gz'), true,
          reason: 'Script should validate downloaded file type');
      
      // Check for binary validation
      expect(content.contains('Expected \'fvm\' binary not found'), true,
          reason: 'Script should validate extracted binary exists');
    });

    test('Script follows DRY principle with helper functions', () async {
      final content = await installScript.readAsString();
      
      // Check for helper function
      expect(content.contains('update_shell_config()'), true,
          reason: 'Script should have helper function to reduce duplication');
      
      // Verify the function is used multiple times
      final helperUsages = 'update_shell_config'.allMatches(content).length;
      expect(helperUsages, greaterThan(3),
          reason: 'Helper function should be used multiple times to reduce duplication');
    });

    test('Script removes YAGNI violations', () async {
      final content = await installScript.readAsString();
      
      // Check that speculative architectures are removed
      expect(content.contains('armv7l'), false,
          reason: 'Script should not support speculative armv7l architecture');
      
      expect(content.contains('ia32'), false,
          reason: 'Script should not support speculative ia32 architecture');
      
      expect(content.contains('riscv64'), false,
          reason: 'Script should not support speculative riscv64 architecture');
      
      // Check that complex XDG_CONFIG_HOME logic is removed
      expect(content.contains('XDG_CONFIG_HOME'), false,
          reason: 'Script should not include over-engineered XDG support');
    });

    test('Script follows KISS principle with simplified logic', () async {
      final content = await installScript.readAsString();
      
      // Check that shell configuration is simplified
      final bashConfigLines = content.split('\n')
          .where((line) => line.contains('bash_config'))
          .length;
      
      // Should be significantly fewer lines than the original complex logic
      expect(bashConfigLines, lessThan(10),
          reason: 'Bash configuration logic should be simplified');
      
      // Check that unused variable is removed
      expect(content.contains('INSTALLED_FVM_VERSION'), false,
          reason: 'Unused variables should be removed for simplicity');
    });

    test('Script has improved error handling', () async {
      final content = await installScript.readAsString();
      
      // Check for cleanup on failure
      expect(content.contains('rm -f fvm.tar.gz'), true,
          reason: 'Script should clean up on failure');
      
      // Check for directory validation
      expect(content.contains('Symlink target directory does not exist'), true,
          reason: 'Script should validate symlink target directory');
      
      // Check for proper error messages
      expect(content.contains('Only x64 and arm64 are supported'), true,
          reason: 'Script should provide clear error messages for unsupported architectures');
    });

    test('Script maintains backward compatibility', () async {
      final content = await installScript.readAsString();
      
      // Check that core functionality is preserved
      expect(content.contains('~/.fvm_flutter'), true,
          reason: 'Script should maintain standard FVM directory');
      
      expect(content.contains('/usr/local/bin/fvm'), true,
          reason: 'Script should maintain standard symlink location');
      
      expect(content.contains('github.com/leoafarias/fvm/releases'), true,
          reason: 'Script should maintain GitHub releases URL');
      
      // Check that shell support is maintained
      expect(content.contains('fish'), true,
          reason: 'Script should maintain fish shell support');
      expect(content.contains('zsh'), true,
          reason: 'Script should maintain zsh shell support');
      expect(content.contains('bash'), true,
          reason: 'Script should maintain bash shell support');
    });

    test('Script has consistent code style', () async {
      final content = await installScript.readAsString();

      // Check for consistent function definitions
      final functionCount = '() {'.allMatches(content).length;
      expect(functionCount, greaterThan(3),
          reason: 'Script should have multiple well-defined functions');

      // Check for consistent error handling pattern
      final errorCallCount = 'error "'.allMatches(content).length;
      expect(errorCallCount, greaterThan(5),
          reason: 'Script should use consistent error handling');

      // Check for consistent info logging
      final infoCallCount = 'info "'.allMatches(content).length;
      expect(infoCallCount, greaterThan(3),
          reason: 'Script should use consistent info logging');
    });

    test('GitHub Actions workflow includes multi-shell testing', () async {
      final workflowFile = File('.github/workflows/install-script-test.yml');
      expect(workflowFile.existsSync(), true,
          reason: 'Install script test workflow should exist');

      final workflowContent = await workflowFile.readAsString();

      // Check for multi-shell job
      expect(workflowContent.contains('test-multi-shell'), true,
          reason: 'Workflow should include multi-shell testing job');

      // Check for shell matrix
      expect(workflowContent.contains('shell: [bash, zsh, fish]'), true,
          reason: 'Workflow should test bash, zsh, and fish shells');

      // Check for shell-specific configurations
      expect(workflowContent.contains('config_file:'), true,
          reason: 'Workflow should specify shell config files');

      expect(workflowContent.contains('export_cmd:'), true,
          reason: 'Workflow should specify shell export commands');

      // Check for shell installation steps
      expect(workflowContent.contains('Install shell'), true,
          reason: 'Workflow should install required shells');

      // Check for shell configuration verification
      expect(workflowContent.contains('Verify shell configuration was added'), true,
          reason: 'Workflow should verify shell configuration');

      // Check for shell execution testing
      expect(workflowContent.contains('Test shell can execute FVM'), true,
          reason: 'Workflow should test FVM execution in each shell');

      // Check for syntax verification
      expect(workflowContent.contains('Verify correct export syntax'), true,
          reason: 'Workflow should verify shell-specific export syntax');
    });

    test('Multi-shell workflow covers all supported shells', () async {
      final workflowFile = File('.github/workflows/install-script-test.yml');
      final workflowContent = await workflowFile.readAsString();

      // Check that all shells from the install script are covered
      final installContent = await installScript.readAsString();

      // Extract shells supported by install script
      final supportedShells = <String>[];
      if (installContent.contains('fish)')) supportedShells.add('fish');
      if (installContent.contains('zsh)')) supportedShells.add('zsh');
      if (installContent.contains('bash)')) supportedShells.add('bash');

      // Verify workflow tests all supported shells
      for (final shell in supportedShells) {
        expect(workflowContent.contains('shell: $shell') ||
               workflowContent.contains('- $shell'), true,
            reason: 'Workflow should test $shell shell');
      }

      expect(supportedShells.length, equals(3),
          reason: 'Install script should support exactly 3 shells (bash, zsh, fish)');
    });
  });
}
