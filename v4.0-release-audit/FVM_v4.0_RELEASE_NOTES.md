# FVM v4.0 Release Notes

## Overview

FVM v4.0 represents a major evolution in Flutter Version Management, introducing powerful new features33. **Command Updates**:
   - Replace `fvm update` with your package manager's update command
   - Note: `fvm flavor` and `fvm destroy` commands remain available with updated behaviorCommand Updates**:
   - Replace `fvm update` with your package manager's update command enterprise environments, improved reliability, and enhanced developer experience. This release includes 63 commits with significant architectural improvements, new commands, and comprehensive workflow enhancements.

## Major Features

### 1. Fork Repository Support 🔀

FVM now supports managing Flutter SDKs from forked repositories, enabling enterprise teams to maintain custom Flutter versions.

**Key capabilities:**
- Add/remove/list fork repositories with `fvm fork` commands
- Install versions from forks using syntax: `fvm install <fork>/<version>`
- Seamless switching between official and forked Flutter versions
- Organized cache structure with fork-specific directories

**Example usage:**
```bash
# Add a fork
fvm fork add mycompany https://github.com/mycompany/flutter.git

# Install from fork
fvm install mycompany/stable
fvm install mycompany/3.19.0

# Use fork version in project
fvm use mycompany/stable
```

### 2. Enhanced Workflow System 🔄

Complete redesign of the workflow system with modular, composable workflows:

**New Workflows:**
- **UpdateVsCodeSettingsWorkflow**: Automatically configures VS Code with correct Flutter SDK paths
- **UpdateMelosSettingsWorkflow**: First-class monorepo support with Melos integration
- **SetupGitIgnoreWorkflow**: Intelligent .gitignore management
- **ValidateFlutterVersionWorkflow**: Enhanced version validation with fork support
- **VerifyProjectWorkflow**: Project structure validation before operations
- **UpdateProjectReferencesWorkflow**: Robust symlink and reference management

**Benefits:**
- Zero-configuration setup for most projects
- Intelligent tool integration (VS Code, Melos, Git)
- Configurable behavior via project settings
- Cross-platform path handling

### 3. Git Clone Fallback Mechanism 🛡️

Improved reliability when installing Flutter versions:

- Attempts optimized clone with `--reference` flag first
- Automatically falls back to standard clone if reference fails
- Handles corrupted git caches gracefully
- Better error messages and recovery options

### 4. Container and CI Support 🐳

Enhanced installation script with intelligent environment detection:

- Automatic detection of Docker, Podman, and CI environments
- Smart root/sudo handling for containers
- `FVM_ALLOW_ROOT=true` override for edge cases
- Improved error handling and recovery

### 5. Integration Test Command 🧪

Hidden command for comprehensive FVM testing:

```bash
fvm integration-test
```

- 39 comprehensive tests covering all FVM functionality
- Real-world testing with actual Flutter SDK installations
- Validates workflows, error handling, and edge cases
- Useful for contributors and CI/CD pipelines

## Breaking Changes ⚠️

### Commands Removed
- **`fvm update`**: Removed - use package manager instead (brew, chocolatey, pub global)

### Configuration Changes
- Config file moved from `.fvm/fvm_config.json` to `.fvmrc` in project root
- Environment variable `FVM_HOME` renamed to `FVM_CACHE_PATH`
- Environment variable `FVM_GIT_CACHE` renamed to `FVM_FLUTTER_URL`

### Behavior Changes
- `fvm install` no longer runs setup by default (use `--setup` flag)
- `fvm use` now runs setup by default (use `--skip-setup` to skip)
- `fvm releases` defaults to stable channel only (use `--all` for all channels)

## Improvements and Fixes

### Installation Script Enhancements
- Unified install/uninstall functionality
- Better architecture detection (x64 and arm64 only)
- Improved PATH management for all shells
- Rate limit avoidance using GitHub redirects
- Enhanced error messages and recovery

### API and Model Updates
- New `FlutterFork` and `GitReference` models
- Enhanced `FlutterVersion` parsing for fork support
- Improved cache service with fork-aware operations
- Better version validation and error handling

### Developer Experience
- Clearer error messages throughout
- Automatic fix for common issues
- Better VS Code and IDE integration
- Improved monorepo support
- Comprehensive test coverage for new features

### Performance
- Optimized git operations with reference clones
- Smarter cache management
- Reduced redundant operations
- Faster version switching

## Migration Guide

### From v3.x to v4.0

1. **Update FVM**:
   ```bash
   # If using brew
   brew upgrade fvm
   
   # If using pub global
   dart pub global activate fvm
   ```

2. **Configuration Migration**:
   - FVM automatically migrates `.fvm/fvm_config.json` to `.fvmrc`
   - Update CI/CD scripts to use new environment variables
   - Add `.fvm/` directory to `.gitignore`

3. **Command Updates**:
   - Replace `fvm update` with your package manager's update command
   - Replace `fvm flavor <name>` with `fvm use <name>`
   - Replace `fvm destroy` with `fvm remove --all`

4. **Script Updates**:
   - Update `FVM_HOME` to `FVM_CACHE_PATH`
   - Update `FVM_GIT_CACHE` to `FVM_FLUTTER_URL`
   - Add `--setup` flag to `fvm install` if needed

## New Configuration Options

Project-level settings in `.fvmrc`:

```json
{
  "flutter": "stable",
  "updateVscodeSettings": true,
  "updateGitIgnore": true,
  "updateMelosSettings": true,
  "runPubGetOnSdkChanges": true,
  "privilegedAccess": true
}
```

## Testing

Comprehensive test coverage added for all new features:
- Fork command operations
- Git clone fallback mechanism
- All new workflows
- Installation script improvements
- Integration test suite

## Documentation Updates

- Enhanced guides for fork management
- Updated workflow documentation
- New quick reference guide
- Improved monorepo setup instructions
- Container deployment guides

## Acknowledgments

This release includes contributions from the community with bug fixes, documentation improvements, and feature suggestions. Special thanks to all contributors who helped make FVM v4.0 possible.

## What's Next

- Further workflow enhancements
- Additional IDE integrations
- Performance optimizations
- Extended fork management features

---

For detailed documentation and guides, visit [fvm.app](https://fvm.app)
For issues and feedback, visit [github.com/leoafarias/fvm](https://github.com/leoafarias/fvm)