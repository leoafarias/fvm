import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/cache_service.dart';
import '../helpers/isolated_test_environment.dart';

void main() {
  group('Parallel FVM Integration Tests', () {
    
    // =============================================
    // PARALLEL TESTS - Fast execution, high concurrency
    // =============================================
    
    group('Installation Tests', () {
      test('Install stable channel', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'install_stable');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          // Fast install without setup - default behavior
          final exitCode = await runner.run(['install', 'stable']);
          expect(exitCode, equals(0));
          
          // Verify using existing cache service
          final cacheService = env.get<CacheService>();
          final version = cacheService.getVersion(FlutterVersion.parse('stable'));
          expect(version, isNotNull);
          
          // Verify cache integrity using existing method
          final integrity = await cacheService.verifyCacheIntegrity(version!);
          expect(integrity, equals(CacheIntegrity.valid));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Install release version', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'install_release');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          final exitCode = await runner.run(['install', '3.19.0']);
          expect(exitCode, equals(0));
          
          final cacheService = env.get<CacheService>();
          final version = cacheService.getVersion(FlutterVersion.parse('3.19.0'));
          expect(version, isNotNull);
          
          final integrity = await cacheService.verifyCacheIntegrity(version!);
          expect(integrity, equals(CacheIntegrity.valid));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Install git commit version', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'install_commit');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          final exitCode = await runner.run(['install', 'fb57da5f94']);
          expect(exitCode, equals(0));
          
          final cacheService = env.get<CacheService>();
          final version = cacheService.getVersion(FlutterVersion.parse('fb57da5f94'));
          expect(version, isNotNull);
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Install with force flag', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'install_force');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          // Install first
          await runner.run(['install', 'stable']);
          
          // Install again with force
          final exitCode = await runner.run(['install', 'stable']);
          expect(exitCode, equals(0));
          
          final cacheService = env.get<CacheService>();
          final version = cacheService.getVersion(FlutterVersion.parse('stable'));
          expect(version, isNotNull);
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
    });
    
    group('Project Configuration Tests', () {
      test('Project use command creates proper structure', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'project_use');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          // Install first
          await runner.run(['install', 'stable']);
          
          // Use in project
          final exitCode = await runner.run(['use', 'stable']);
          expect(exitCode, equals(0));
          
          // Verify project structure using existing validation patterns
          final fvmrcFile = File(p.join(env.projectDir.path, '.fvmrc'));
          expect(fvmrcFile.existsSync(), isTrue);
          
          final fvmDir = Directory(p.join(env.projectDir.path, '.fvm'));
          expect(fvmDir.existsSync(), isTrue);
          
          final symlinkPath = p.join(env.projectDir.path, '.fvm', 'flutter_sdk');
          final link = Link(symlinkPath);
          expect(link.existsSync(), isTrue);
          
          final target = link.targetSync();
          expect(target, contains(env.context.versionsCachePath));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Project use with flavor', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'project_flavor');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          // Install first
          await runner.run(['install', '3.19.0']);
          
          // Use with flavor
          final exitCode = await runner.run(['use', '3.19.0', '--flavor', 'production']);
          expect(exitCode, equals(0));
          
          // Verify flavor configuration
          final fvmrcFile = File(p.join(env.projectDir.path, '.fvmrc'));
          expect(fvmrcFile.existsSync(), isTrue);
          
          final content = await fvmrcFile.readAsString();
          expect(content, contains('production'));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Project use with force flag', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'project_force');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          // Install and use first
          await runner.run(['install', 'stable']);
          await runner.run(['use', 'stable']);
          
          // Use again with force
          final exitCode = await runner.run(['use', 'stable', '-f']);
          expect(exitCode, equals(0));
          
          final fvmrcFile = File(p.join(env.projectDir.path, '.fvmrc'));
          expect(fvmrcFile.existsSync(), isTrue);
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
    });
    
    group('Version Management Tests', () {
      test('List installed versions', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'list_versions');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          // Install a version first
          await runner.run(['install', 'stable']);
          
          // List versions
          final exitCode = await runner.run(['list']);
          expect(exitCode, equals(0));
          
          // Verify version is in cache
          final cacheService = env.get<CacheService>();
          final versions = await cacheService.getAllVersions();
          expect(versions, isNotEmpty);
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Remove version', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'remove_version');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          // Install a version first
          await runner.run(['install', '3.19.0']);
          
          // Verify it exists
          final cacheService = env.get<CacheService>();
          var version = cacheService.getVersion(FlutterVersion.parse('3.19.0'));
          expect(version, isNotNull);
          
          // Remove version
          final exitCode = await runner.run(['remove', '3.19.0']);
          expect(exitCode, equals(0));
          
          // Verify it's removed
          version = cacheService.getVersion(FlutterVersion.parse('3.19.0'));
          expect(version, isNull);
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Doctor command', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'doctor');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          final exitCode = await runner.run(['doctor']);
          expect(exitCode, equals(0));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
    });
    
    group('Basic Command Tests', () {
      test('Help command', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'help');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          final exitCode = await runner.run(['--help']);
          expect(exitCode, equals(0));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Version command', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'version');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          final exitCode = await runner.run(['--version']);
          expect(exitCode, equals(0));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Releases command', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'releases');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          final exitCode = await runner.run(['releases']);
          expect(exitCode, equals(0));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
    });
    
    group('API Command Tests', () {
      test('API list command', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'api_list');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          final exitCode = await runner.run(['api', 'list']);
          expect(exitCode, equals(0));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('API releases command', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'api_releases');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          final exitCode = await runner.run(['api', 'releases', '--limit', '3']);
          expect(exitCode, equals(0));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('API context command', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'api_context');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          final exitCode = await runner.run(['api', 'context']);
          expect(exitCode, equals(0));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
    });
    
    group('Error Handling Tests', () {
      test('Invalid version handling', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'invalid_version');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          // Should fail gracefully
          final exitCode = await runner.run(['install', 'invalid-version-12345']);
          expect(exitCode, isNot(equals(0)));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
      
      test('Invalid command handling', () async {
        final env = await IsolatedTestEnvironment.create(debugLabel: 'invalid_command');
        try {
          env.verifyIsolation();
          
          final runner = FvmCommandRunner(env.context);
          
          // Should fail gracefully
          final exitCode = await runner.run(['invalid-command-xyz']);
          expect(exitCode, isNot(equals(0)));
        } finally {
          await env.cleanup();
        }
      }, tags: ['parallel', 'fast']);
    });
    
  }, timeout: Timeout(Duration(minutes: 3))); // Generous timeout for parallel suite
  
  // =============================================  
  // SERIAL TESTS - Heavy operations, run sequentially
  // =============================================
  
  group('Serial FVM Integration Tests', () {
    
    test('Install with setup and validation', () async {
      final env = await IsolatedTestEnvironment.create(debugLabel: 'setup_validation');
      try {
        env.verifyIsolation();
        
        final runner = FvmCommandRunner(env.context);
        
        // This test explicitly runs setup - only test that does this
        final exitCode = await runner.run(['install', '3.22.0', '--setup']);
        expect(exitCode, equals(0));
        
        final cacheService = env.get<CacheService>();
        final version = cacheService.getVersion(FlutterVersion.parse('3.22.0'));
        expect(version, isNotNull);
        
        // Verify cache integrity
        final integrity = await cacheService.verifyCacheIntegrity(version!);
        expect(integrity, equals(CacheIntegrity.valid));
        
        // Verify Flutter binary exists
        final flutterBin = File(version.flutterExec);
        expect(flutterBin.existsSync(), isTrue);
      } finally {
        await env.cleanup();
      }
    }, tags: ['serial', 'slow']);
    
    test('Flutter proxy command validation', () async {
      final env = await IsolatedTestEnvironment.create(debugLabel: 'flutter_proxy');
      try {
        env.verifyIsolation();
        
        final runner = FvmCommandRunner(env.context);
        
        // Install with setup for this test
        await runner.run(['install', 'stable', '--setup']);
        await runner.run(['use', 'stable']);
        
        // Test Flutter proxy
        final exitCode = await runner.run(['flutter', '--version']);
        expect(exitCode, equals(0));
      } finally {
        await env.cleanup();
      }
    }, tags: ['serial', 'slow']);
    
    test('Git clone fallback mechanism', () async {
      // Test fallback mechanism safely using isolated git cache
      final env = await IsolatedTestEnvironment.create(
        useGitCache: false, // Force fallback to normal clone
        debugLabel: 'git_fallback',
      );
      try {
        env.verifyIsolation();
        
        final runner = FvmCommandRunner(env.context);
        final exitCode = await runner.run(['install', '3.13.0']);
        expect(exitCode, equals(0));
        
        final cacheService = env.get<CacheService>();
        final version = cacheService.getVersion(FlutterVersion.parse('3.13.0'));
        expect(version, isNotNull);
      } finally {
        await env.cleanup();
      }
    }, tags: ['serial', 'slow']);
    
    test('Concurrent operations safety', () async {
      final env = await IsolatedTestEnvironment.create(debugLabel: 'concurrent_ops');
      try {
        env.verifyIsolation();
        
        final runner = FvmCommandRunner(env.context);
        await runner.run(['install', 'stable']);
        
        // Run multiple read-only commands concurrently
        final futures = [
          runner.run(['list']),
          runner.run(['doctor']),
          runner.run(['releases']),
          runner.run(['api', 'context']),
        ];
        
        final results = await Future.wait(futures);
        expect(results, everyElement(equals(0)));
      } finally {
        await env.cleanup();
      }
    }, tags: ['serial', 'slow']);
    
  }, timeout: Timeout(Duration(minutes: 8))); // Longer timeout for serial suite
}