# FVM 4.0.0 Release

We're excited to announce FVM 4.0.0, a major release that brings enterprise-grade features to Flutter version management. This release introduces fork repository support, modular workflow architecture, and enhanced integrations for teams managing complex Flutter environments.

## 🎉 Highlights

### 🔀 Fork Repository Support
Manage Flutter SDKs from custom or forked repositories - perfect for enterprise teams with proprietary Flutter modifications.

```bash
# Add a fork
fvm fork add mycompany https://github.com/mycompany/flutter.git

# Install from fork
fvm install mycompany/stable
fvm install mycompany/3.19.0

# Use fork version in project
fvm use mycompany/stable
```

### 🔗 Melos Integration
First-class monorepo support with automatic `sdkPath` management in `melos.yaml`.

### 🏗️ Modular Workflow Architecture
9 new workflows for better separation of concerns and maintainability.

## ✨ What's New

### Major Features
- **Fork repository management** - Complete system for managing custom Flutter distributions
- **`fvm fork` commands** - Add, remove, and list fork repositories
- **Fork version syntax** - Install using `<fork>/<version>` format
- **Melos integration** - Automatic monorepo configuration
- **Integration testing** - Hidden `fvm integration-test` command for comprehensive testing

### Architecture Improvements
- **Modular workflows** - 9 new workflows including:
  - `UpdateMelosSettingsWorkflow` - Melos integration
  - `SetupGitIgnoreWorkflow` - Smart .gitignore management
  - `UpdateVsCodeSettingsWorkflow` - VS Code configuration
  - `ValidateFlutterVersionWorkflow` - Enhanced validation
  - And 5 more for complete project lifecycle management
- **New services** - GitService, ProcessService, AppConfigService
- **File locking** - Prevents concurrent operations for better reliability
- **Git clone fallback** - Automatic recovery when reference clones fail

### Developer Experience
- **Better error messages** - Enhanced stack trace preservation and helpful error output
- **Fork-aware caching** - Organized cache structure: `~/.fvm/versions/<fork>/<version>`
- **Configuration option** - New `updateMelosSettings` flag for Melos control
- **Runtime deprecation warnings** - Clear warnings for unsupported environment variables
- **Legacy environment variable fallback** - `FVM_HOME` works as fallback when `FVM_CACHE_PATH` is not set
- **Enhanced environment variable processing** - Improved logic in AppConfigService for better reliability
- **Better environment variable precedence** - Clear fallback behavior and error messaging

## 💔 Breaking Changes

- **Removed `fvm update`** - Use your package manager instead (`brew upgrade fvm`, `dart pub global activate fvm`)
- **Removed deprecated environment variable** - `FVM_GIT_CACHE` (deprecated since v3.0.0) is no longer supported
  - Use `FVM_FLUTTER_URL` instead of `FVM_GIT_CACHE`
  - **Note**: `FVM_HOME` is still supported as a fallback for `FVM_CACHE_PATH` but shows a deprecation warning

## 📦 Installation

### macOS/Linux
```bash
# Homebrew (recommended)
brew tap leoafarias/fvm
brew install fvm

# Dart pub
dart pub global activate fvm

# Standalone script
curl -fsSL https://fvm.app/install.sh | bash
```

### Windows
```powershell
# Chocolatey
choco install fvm

# Dart pub
dart pub global activate fvm
```

## 🚀 Migration Guide

### From v3.x to v4.0

1. **Update FVM**:
   ```bash
   brew upgrade fvm  # or your package manager
   ```

2. **Update environment variables** (if used):
   - Replace `FVM_GIT_CACHE` with `FVM_FLUTTER_URL` (required - `FVM_GIT_CACHE` no longer works)
   - Consider replacing `FVM_HOME` with `FVM_CACHE_PATH` (optional - `FVM_HOME` still works as fallback)

3. **For enterprise users** - Set up your forks:
   ```bash
   fvm fork add company https://github.com/company/flutter.git
   fvm use company/stable
   ```

## 📊 By the Numbers

- **9** new workflows added
- **3** new services implemented
- **4** breaking changes
- **1** major new feature system (forks)
- **100%** backward compatible with existing projects

## 🙏 Acknowledgments

This release was made possible by contributions from the Flutter community. Special thanks to everyone who reported issues, submitted PRs, and provided feedback.

## 📚 Documentation

- Full documentation: [fvm.app](https://fvm.app)
- Fork management guide: [fvm.app/docs/guides/fork-management](https://fvm.app/docs/guides/fork-management)
- API reference: [fvm.app/docs/api](https://fvm.app/docs/api)

## 🐛 Bug Reports

Found an issue? Please report it on our [issue tracker](https://github.com/leoafarias/fvm/issues).

---

**Full Changelog**: https://github.com/leoafarias/fvm/compare/3.2.1...4.0.0