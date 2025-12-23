import 'dart:io';

import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/base_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/utils/context.dart';

/// Isolated test environment for FVM integration tests
/// 
/// Creates a completely isolated test environment with:
/// - Isolated project directory (temp)
/// - Isolated Flutter version cache (temp) 
/// - Shared git cache using FVM's existing infrastructure (~/.fvm/cache.git)
/// 
/// This allows parallel test execution while leveraging git cache optimization.
class IsolatedTestEnvironment {
  final Directory projectDir;
  final Directory cacheDir;
  final FvmContext context;
  
  IsolatedTestEnvironment._({
    required this.projectDir,
    required this.cacheDir,
    required this.context,
  });
  
  /// Creates isolated test environment using FVM's existing git cache infrastructure
  static Future<IsolatedTestEnvironment> create({
    bool useGitCache = true,
    String? debugLabel,
  }) async {
    final testId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create isolated directories for test-specific cache
    final projectDir = await Directory.systemTemp.createTemp('fvm_test_proj_${testId}_');
    final cacheDir = await Directory.systemTemp.createTemp('fvm_test_cache_${testId}_');
    
    // Get shared git cache path using existing FVM infrastructure
    String? gitCachePath;
    if (useGitCache) {
      // CRITICAL: Use existing FVM git cache infrastructure
      final globalContext = FvmContext.create();
      gitCachePath = globalContext.gitCachePath; // ~/.fvm/cache.git
      
      // Ensure git cache exists using existing GitService with proper locking
      try {
        final gitService = globalContext.get<GitService>();
        await gitService.updateLocalMirror(); // Thread-safe with existing locks
      } catch (e) {
        // Git cache creation failed - continue without cache
        final logger = globalContext.get<Logger>();
        logger.warn('Git cache initialization failed, continuing without cache: $e');
        gitCachePath = null;
        useGitCache = false;
      }
    }
    
    // Create isolated context using existing FVM patterns
    final context = FvmContext.create(
      debugLabel: debugLabel ?? 'isolated_test_$testId',
      workingDirectoryOverride: projectDir.path,
      isTest: true,
      configOverrides: AppConfig(
        cachePath: cacheDir.path,        // Isolated per test
        gitCachePath: gitCachePath,      // Shared ~/.fvm/cache.git
        useGitCache: useGitCache,
      ),
    );
    
    final env = IsolatedTestEnvironment._(
      projectDir: projectDir,
      cacheDir: cacheDir,
      context: context,
    );
    
    // Log setup for debugging
    final logger = context.get<Logger>();
    logger.debug('IsolatedTestEnvironment created:');
    logger.debug('  Project: ${projectDir.path}');
    logger.debug('  Cache: ${cacheDir.path}');
    logger.debug('  GitCache: ${gitCachePath ?? "disabled"} (shared)');
    
    return env;
  }
  
  /// Cleanup isolated test environment
  /// 
  /// Removes the isolated project and cache directories.
  /// Does NOT touch the shared git cache.
  Future<void> cleanup() async {
    try {
      if (projectDir.existsSync()) {
        await projectDir.delete(recursive: true);
      }
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      // Log but don't fail tests on cleanup errors
      final logger = context.get<Logger>();
      logger.warn('Test cleanup warning (non-fatal): $e');
    }
  }
  
  /// Verify the test environment is properly isolated
  void verifyIsolation() {
    if (!projectDir.path.contains('fvm_test_proj_')) {
      throw StateError('Project directory is not properly isolated');
    }
    if (!cacheDir.path.contains('fvm_test_cache_')) {
      throw StateError('Cache directory is not properly isolated');  
    }
    
    // Git cache should be shared (if enabled)
    if (context.gitCache && !context.gitCachePath.contains('fvm')) {
      throw StateError('Git cache path is not using FVM infrastructure');
    }
  }
  
  /// Get a service from the isolated context
  T get<T extends Contextual>() {
    return context.get<T>();
  }
}