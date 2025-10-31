# Issue #935: [Feature Request] Support for RISC-V architecture

## Metadata
- **Reporter**: @vhaudiquet
- **Created**: 2025-10-08
- **Reported Version**: Not specified (request for future releases)
- **Issue Type**: feature
- **URL**: https://github.com/leoafarias/fvm/issues/935

## Problem Summary
FVM currently publishes binaries and install scripts for x64 and arm64 only. Running the install script on a RISC-V machine exits with “Unsupported architecture” and the documentation likewise lists only x64/arm64 as supported. The reporter asks for official RISC-V support, noting that the Dart SDK already ships builds for that architecture.

## Version Context
- Reported against: N/A (capability gap)
- Current version: v4.0.0
- Version-specific: no — request is for expanding platform coverage beyond any specific FVM release

## Validation Steps
1. Reviewed `scripts/install.sh` and confirmed that architectures other than `x86_64` and `arm64|aarch64` trigger an error (“Only x64 and arm64 are supported”).
2. Checked the published docs (`docs/pages/documentation/getting-started/installation.mdx`) where the supported platform table lists macOS/Linux: x64, arm64 only.
3. Looked at release packaging code (`tool/grind.dart` + GitHub workflows) and found no tasks for a RISC-V artifact, implying the build pipeline does not produce binaries for that target.

## Evidence
```
$ nl -ba scripts/install.sh | sed -n '242,252p'
   242 case "$ARCH" in
   243   x86_64)
   244     ARCH='x64'
   245     ;;
   246   arm64|aarch64)
   247     ARCH='arm64'
   248     ;;
   249   *)
   250     error "Unsupported architecture: $ARCH. Only x64 and arm64 are supported."
   251     ;;

$ nl -ba docs/pages/documentation/getting-started/installation.mdx | sed -n '128,136p'
   130 | Platform | Architecture | Support |
   131 |----------|-------------|---------|
   132 | macOS | x64, arm64 | ✅ |
   133 | Linux | x64, arm64 | ✅ |
   134 | Windows | x64 | ✅ (via PowerShell/Chocolatey) |

$ sed -n '1,80p' tool/grind.dart
... pkg.addAllTasks(); // default cli_pkg targets (no riscv64 build defined)
```

## Current Status in v4.0.0
- [x] Still reproducible (RISC-V rejected by install script)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The install script hard-codes support for `x64` and `arm64` architectures and throws for everything else. Release automation (via `cli_pkg`) only publishes binaries for those targets, and documentation reflects that limitation. No RISC-V artifacts exist, so even manual installs via the script fail early.

### Proposed Solution
1. **Add architecture detection**: Extend `scripts/install.sh` (and the copy in `docs/public/install.sh`) to recognize `riscv64`/`riscv64gc` and map it to an `ARCH='riscv64'` label instead of erroring. Update the error message to list the supported set dynamically.
2. **Produce RISC-V binaries**:
   - Configure `cli_pkg` to build Linux RISC-V executables (likely via `pkg.linuxPackageTargets` + defining a `pkg.RustTarget`? confirm with cli_pkg docs) or fall back to distributing the script snapshot if native compilation is unavailable.
   - Update `.github/workflows/release.yml` to run the new Grind task that publishes the `fvm-<version>-linux-riscv64.tar.gz` asset.
   - Ensure the Docker image build (if RISC-V-friendly) either cross-compiles or documents lack of support.
3. **Homebrew and other package managers**: Update `tool/fvm.template.rb` and any other packaging templates to account for the new architecture, or ensure they gracefully skip if not needed.
4. **Documentation**: Adjust the Supported Platforms table to include RISC-V once binaries exist and add instructions for installing via `dart pub global activate fvm` as an interim option if native builds lag.
5. **Validation**:
   - Run the installer on a RISC-V environment (QEMU or actual hardware) to confirm the new path works.
   - Execute `fvm doctor` and a basic `fvm install stable` to verify end-to-end functionality.

### Alternative Approaches
- Ship only a Dart snapshot (`dart pub global activate fvm`) as the official method for RISC-V, skipping native binaries. This reduces build complexity but offers worse startup time and no install script parity.

### Dependencies & Risks
- Need access to a RISC-V toolchain/QEMU runner in CI; cross-compilation support for `dart compile exe` must be verified, otherwise fallback artifacts required.
- Upstream Flutter releases currently lack RISC-V archives; users may need to rely on custom `flutterUrl` or building from source until official support lands. Document this limitation clearly to avoid confusion.

## Classification Recommendation
- Priority: **P2 - Medium** (feature parity request; no current functionality broken for primary platforms)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- Coordinate with Dart/Flutter teams to confirm availability of RISC-V SDK/toolchain builds. If unavailable, set expectations in the issue and docs about timelines or required upstream work.
