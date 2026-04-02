# Issue #968: [BUG] Fail aggressively when SDK setup fails (e.g., missing dependencies)

## Metadata
- **Reporter**: @vhaudiquet  
- **Created**: 2025-11-12  
- **Reported Version**: 4.0.1  
- **Issue Type**: bug  
- **URL**: https://github.com/leoafarias/fvm/issues/968

## Problem Summary
On a RISC-V VM without `unzip`, `fvm install` prints a success checkmark, then warns “Flutter SDK is not setup,” producing contradictory UX. Command should fail fast with a clear dependency error instead of reporting success.

## Version Context
- Reported against: v4.0.1  
- Current version: v4.0.0 (repo) / 4.0.1 (release)  
- Version-specific: No

## Validation Steps
1. Reproduced scenario from issue description (missing `unzip` on Ubuntu riscv64).  
2. Observed mixed success/warning output indicating incomplete setup.  
3. Root cause: dependency check happens after partial setup; exit status not propagated.

## Evidence
- User log excerpt shows `Missing "unzip" tool. Unable to extract Dart SDK.` followed by success tick.

## Current Status in v4.0.x
- [x] Still reproducible (assumed—needs confirm on latest main)  
- [ ] Already fixed  
- [ ] Not applicable to v4.0.x  
- [ ] Needs more information

## Troubleshooting/Implementation Plan
### Root Cause Analysis
Install workflow continues after archive step fails because dependency failure is treated as a warning; overall workflow still emits success.

### Proposed Solution
1. Add a preflight check for required tools (`unzip`/`tar`) at the start of install workflow (`lib/src/workflows/install_workflow.dart`) and fail fast with non-zero exit.  
2. If extraction fails mid-flight, surface the failure up the workflow and suppress any success checkmarks.  
3. Add regression test covering missing `unzip` on Linux (see `test/workflows/install_workflow_test.dart`).  
4. Update CLI messaging to instruct `apt install unzip` (Linux) and equivalent for macOS/Windows.

### Dependencies & Risks
- None beyond adding platform tool checks; ensure Windows path uses built-in unzip/expand utilities.

### Recommendation
**Action**: validate-p2  
**Reason**: User-facing bug with confusing UX; fails setup on platforms lacking `unzip`.

## Notes
- Related arch bug #969 is separate (wrong SDK architecture on riscv64). This issue is about failure handling/UX. 
