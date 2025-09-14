# FVM GitHub Workflows

## Active Workflows

### `release.yml` 
**Trigger**: GitHub release published + manual dispatch  
**Purpose**: Main deployment pipeline triggered by publishing a GitHub release  
**Process**:
1. **Test** - Run all tests and quality checks
2. **Validate** - Extract version, update files, validate with `dart pub publish --dry-run`
3. **Deploy** - Deploy to all platforms simultaneously:
   - 📦 pub.dev 
   - 🐧 GitHub Linux binaries
   - 🍎 GitHub macOS binaries + Homebrew
   - 🪟 GitHub Windows binaries + Chocolatey
   - 🐳 Docker Hub

**Key Feature**: ⚡ **Fails fast** if version validation fails, saving time and resources

**Usage**: Create and publish a GitHub release - everything deploys automatically!

### `test.yml`
**Trigger**: Push, PR, workflow_call  
**Purpose**: Run all tests and quality checks  
**Used by**: Other workflows for validation before deployment

### `test-install.yml` 
**Trigger**: Manual dispatch  
**Purpose**: Test FVM installation across different platforms

## Standalone Deploy Workflows

### Platform-Specific Deploy Workflows
- `deploy_docker.yml` - Standalone Docker deployment
- `deploy_homebrew.yml` - Standalone Homebrew updates  
- `deploy_macos.yml` - Standalone macOS deployment
- `deploy_windows.yml` - Standalone Windows deployment

## Recommended Release Process

### 🚀 Standard Release (Recommended)

1. **Code ready on main branch**
   - All changes merged and tested
   - No need to update versions manually

2. **Create GitHub Release**
   - Go to [GitHub Releases](https://github.com/leoafarias/fvm/releases)
   - Click "Create a new release"
   - Choose tag: `v4.0.0-beta.2` (follows semver with 'v' prefix)
   - Write detailed release notes
   - Click "Publish release"

3. **Automatic Deployment**
   - `release.yml` triggers automatically
   - Monitor progress in [Actions](https://github.com/leoafarias/fvm/actions)
   - All platforms deployed simultaneously

### ⚡ Emergency Release (Alternative)

For hotfixes or urgent releases, use individual platform workflows:

- Manual dispatch `deploy_homebrew.yml` for Homebrew-only updates
- Manual dispatch `deploy_docker.yml` for Docker-only updates  
- Manual dispatch individual platform workflows as needed

Note: Requires manual version management in `pubspec.yaml`.

## Version Management

- **Primary workflow**: Version extracted from GitHub release tag
- **Standalone workflows**: Version must be manually updated in `pubspec.yaml`
- **Format**: Tags should follow semver with 'v' prefix: `v4.0.0-beta.2`
- **Validation**: `dart pub publish --dry-run` validates version before deployment

## Troubleshooting

### Workflow doesn't trigger
- Ensure release is **published**, not just created as draft
- Check that tag follows `v*` pattern
- Verify all required secrets are configured

### Binary upload fails
- Check if GitHub release exists with matching tag
- Verify `GITHUB_TOKEN` has release permissions
- Ensure standalone binaries built successfully

### Platform deployment fails
- Check platform-specific tokens (Chocolatey, Homebrew, Docker)
- Verify runner OS matches deployment target
- Review build logs for specific error details