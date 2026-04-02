# Issue #969: [BUG] RISC-V: Download the right Dart SDK (and engine) for real RISC-V support

## Metadata
- **Reporter**: @vhaudiquet  
- **Created**: 2025-11-12  
- **Reported Version**: 4.0.1  
- **Issue Type**: bug  
- **URL**: https://github.com/leoafarias/fvm/issues/969

## Problem Summary
On riscv64, `fvm install` downloads the Linux arm64 Dart SDK from the Flutter engine, leading to exec format errors when building Flutter tools. Flutter upstream currently lacks official riscv64 engine binaries.

## Version Context
- Reported against: v4.0.1  
- Current version: v4.0.0 (repo) / 4.0.1 (release)  
- Version-specific: No (platform-specific)

## Validation Steps
1. User reproduction on Ubuntu riscv64 shows arm64 SDK download and subsequent exec format error.  
2. Root cause: architecture mapping defaults to arm64 for Flutter archives; no riscv64 artifact exists upstream.

## Evidence
- Log: “Downloading Linux arm64 Dart SDK… cannot execute binary file: Exec format error”.

## Current Status in v4.0.x
- [x] Still reproducible (upstream lacks riscv64 engine)  
- [ ] Already fixed  
- [ ] Not applicable to v4.0.x  
- [ ] Needs more information

## Troubleshooting/Implementation Plan
### Root Cause Analysis
Arch resolver maps riscv64 → arm64; Flutter engine releases do not ship riscv64 archives, so FVM downloads an incompatible binary.

### Proposed Solution
1. Update architecture detection to recognize `riscv64` and block with a clear, early error explaining that Flutter engine binaries are not published for this arch.  
2. Optionally allow a “Dart-only” install path (download Dart SDK directly from dart.dev) when `--dart-only` flag is provided, documenting limitations (no Flutter engine).  
3. Add tests for riscv64 detection in install workflow to ensure arm64 is never fetched on riscv64.  
4. Documentation: note unsupported status and potential community-built engine paths; point to upstream Flutter issue for tracking.

### Dependencies & Risks
- True Flutter support depends on upstream providing riscv64 engine builds; interim behavior should fail fast with guidance.

### Recommendation
**Action**: validate-p2  
**Reason**: Platform-specific install failure; must fail clearly and avoid pulling wrong architecture.

## Notes
- Related UX bug #968 covers dependency error handling; this issue is architecture/availability.
