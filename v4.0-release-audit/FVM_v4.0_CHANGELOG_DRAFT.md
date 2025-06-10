# FVM v4.0.0 Changelog

## 🎯 Highlights

- **Fork Repository Support**: Manage Flutter SDKs from custom/forked repositories
- **Enhanced Workflows**: Zero-config setup with automatic VS Code, Melos, and Git integration  
- **Improved Reliability**: Git clone fallback mechanism and better error recovery
- **Container Support**: Smart root/sudo handling for Docker, Podman, and CI environments
- **Better Testing**: Comprehensive integration test suite with 39 tests

## ✨ New Features

### Fork Repository Management
- Add custom Flutter repositories with `fvm fork add <name> <url>`
- Install from forks: `fvm install <fork>/<version>`
- List configured forks: `fvm fork list`
- Remove forks: `fvm fork remove <name>`
- Hierarchical cache organization: `cache/versions/<fork>/<version>`

### Enhanced Workflow System  
- **Auto VS Code Configuration**: Automatically sets Flutter SDK path in settings
- **Melos Integration**: First-class monorepo support with automatic configuration
- **Smart .gitignore**: Intelligent management of FVM entries
- **Project Validation**: Ensures valid project structure before operations
- **Configurable Behavior**: Control each workflow via project settings

### Git Clone Fallback
- Attempts optimized clone with `--reference` first
- Automatically falls back on reference errors
- Handles corrupted git caches gracefully
- Better error messages and recovery

### Container & CI Support
- Auto-detects Docker, Podman, and CI environments
- Allows root execution in containers with smart detection
- Manual override via `FVM_ALLOW_ROOT=true`
- Enhanced error handling for container scenarios

### Integration Testing
- Hidden `fvm integration-test` command
- 39 comprehensive tests covering all functionality
- Real Flutter SDK installation testing
- Useful for contributors and CI validation

### File Lock Mechanism
- Prevents concurrent operations on same resources
- Important for CI/CD environments
- Comprehensive test coverage

## 🚀 Improvements

### Installation Script
- Unified install/uninstall in single script
- Better architecture detection (x64 and arm64 only)
- Improved PATH management for all shells
- Rate limit avoidance using GitHub redirects
- Enhanced error messages

### Developer Experience
- Clearer, actionable error messages
- Better progress indicators
- Automatic fixes for common issues
- Interactive prompts only when necessary
- Comprehensive test helpers

### Performance
- Optimized git operations with reference clones
- Smarter cache management
- Reduced redundant operations
- Faster version switching

### API Enhancements
- New subcommands: `api list`, `api releases`, `api project`, `api context`
- Better JSON formatting
- Enhanced error responses
- Fork-aware context

## 🐛 Bug Fixes

- Fix Flutter upgrade channel check validation (#859)
- Preserve stack traces for git validation errors (#856)
- Fix installation bug (#792)
- Fix typos in documentation and code (#849, #854, #778)
- Correct variable name from FMV_DIR_BIN to FVM_DIR_BIN (#722)

## 💥 Breaking Changes

### Removed Commands
- `fvm update` - Use package manager (brew/chocolatey/pub) instead

### Configuration Changes
- Config moved from `.fvm/fvm_config.json` to `.fvmrc` in project root
- `FVM_HOME` → `FVM_CACHE_PATH` environment variable
- `FVM_GIT_CACHE` → `FVM_FLUTTER_URL` environment variable

### Behavior Changes
- `fvm install` no longer runs setup by default (add `--setup` flag)
- `fvm use` now runs setup by default (add `--skip-setup` to skip)
- `fvm releases` defaults to stable channel only (add `--all` for all)
- Commit hashes now require minimum 10 characters
- Dropped `armv7l` architecture support

### Removed Files/APIs
- `config_repository.dart` service
- `global_version_service.dart` service
- Various utility files (`cli_util.dart`, `commands.dart`, etc.)

## 📚 Documentation

- New workflow documentation guide
- Quick reference guide added
- Enhanced monorepo setup instructions
- Version parsing implementation docs
- Comprehensive testing methodology guide
- Updated installation and basic command guides

## 🔧 Technical Changes

### New Models
- `FlutterFork` - Fork repository definitions
- `GitReference` - Git-based version references  
- `LogLevel` - Logging configuration

### New Services
- `AppConfigService` - Replaces ConfigRepository
- `ProcessService` - Centralized process execution
- `GitService` - Git operations management

### Architecture Improvements
- Modular workflow system with dependency injection
- Better separation of concerns
- Enhanced error handling throughout
- Cleaner service layer

## 📦 Dependencies

- Updated dependencies for Dart 3.x compatibility
- New dependencies for enhanced functionality
- Removed unused dependencies

## 🙏 Contributors

Thanks to all contributors who helped make v4.0 possible:
- Leo Farias (@leoafarias) - Main development
- Community contributors - Bug fixes and improvements
- Flat-data bot - Release updates

## 📝 Migration Guide

See the [Migration Guide](https://fvm.app/docs/migration/v4) for detailed upgrade instructions.

### Quick Migration Steps:
1. Update FVM via your package manager
2. Let FVM auto-migrate your config files
3. Update environment variables in scripts
4. Replace removed commands
5. Add `.fvm/` to `.gitignore`

---

**Full Changelog**: https://github.com/leoafarias/fvm/compare/v3.2.1...v4.0.0