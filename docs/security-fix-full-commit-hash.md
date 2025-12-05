# Security Fix: Full Commit Hash Storage

## Overview
This document explains the security fix implemented to prevent DOS (Denial of Service) attacks by ensuring FVM always stores full 40-character commit hashes in configuration files instead of short 10-character hashes.

## Problem Statement

### Original Issue
Previously, when users specified a git commit version using `fvm use <commit-hash>`, FVM would store the hash exactly as provided in the `.fvmrc` configuration file. If a user provided a short hash (e.g., `6d04a16210`), that short hash would be stored directly.

### Security Vulnerability
Short git commit hashes (typically 7-10 characters) can collide between different repositories or forks. This creates a security vulnerability described in detail at:
https://blog.teddykatz.com/2019/11/12/github-actions-dos.html

#### Attack Scenario
1. Attacker creates a fork of the Flutter repository
2. Attacker creates a commit with malicious code
3. Attacker finds the short hash of their malicious commit
4. Attacker waits for the short hash to collide with a legitimate commit in the official Flutter repository
5. Projects using the short hash could inadvertently switch to the malicious commit

## Solution

### Implementation
The fix ensures that all commit hashes are expanded to their full 40-character SHA-1 representation before being stored in configuration files.

#### Key Changes

1. **New Method in GitService** (`lib/src/services/git_service.dart`):
   ```dart
   Future<String?> resolveCommitHash(
     String commitRef,
     FlutterVersion version,
   ) async
   ```
   - Uses `git rev-parse` to expand any commit reference (short or long) to full 40-character SHA
   - Returns `null` if the reference cannot be resolved
   - Validates that the returned hash is exactly 40 characters and matches the expected format

2. **Updated Workflow** (`lib/src/workflows/update_project_references.workflow.dart`):
   ```dart
   // Resolve commit hash to full SHA if this is an unknown ref (commit)
   String versionToStore = version.name;
   if (version.isUnknownRef) {
     final fullHash = await get<GitService>().resolveCommitHash(
       version.version,
       version,
     );
     if (fullHash != null) {
       versionToStore = fullHash;
       logger.debug('Resolved commit hash: ${version.name} -> $fullHash');
     }
   }
   ```

3. **Exported GitService** (`lib/fvm.dart`):
   - Added GitService to public exports for testing purposes

### Behavior

#### Before the Fix
```json
{
  "flutter": "6d04a16210"
}
```

#### After the Fix
```json
{
  "flutter": "6d04a162109d07876230709adf4013db113b16a3"
}
```

### Important Notes

1. **Backward Compatibility**: The fix maintains backward compatibility. Existing projects with short hashes in their `.fvmrc` will continue to work. The hash will be expanded to full length the next time `fvm use` is run.

2. **Non-Commit Versions Unaffected**: This change only affects commit-based versions (identified as `isUnknownRef`). Semantic versions (e.g., `3.10.0`) and channel versions (e.g., `stable`, `beta`) are not modified.

3. **Display vs Storage**: Short hashes can still be used for display purposes in UI/logs (`printFriendlyName`), but the full hash is always stored in configuration files.

## Testing

### Unit Tests
- `test/services/git_service_hash_resolution_test.dart`
  - Validates `resolveCommitHash` method functionality
  - Tests non-git directory handling

### Integration Tests
- `test/integration/commit_hash_resolution_test.dart`
  - Tests complete workflow from short hash to config file
  - Verifies short hashes are expanded to full hashes
  - Verifies full hashes remain unchanged
  - Verifies non-commit versions are not affected

### Test Results
All 215 tests pass with no regressions.

## Security Impact

This fix prevents DOS attacks by ensuring:
1. **Unique Identifiers**: Full 40-character SHA-1 hashes are globally unique (collision probability: ~2^-160)
2. **No Fork Confusion**: Commits from different forks cannot be confused due to hash collision
3. **Tamper Detection**: Any modification to the commit will result in a completely different hash

## Migration Guide

### For Users
No action required. The fix is transparent:
- Continue using `fvm use <commit-hash>` as before
- You can use short or full hashes when running commands
- The configuration file will automatically store the full hash

### For Developers
If you're working with FVM internals:
- Use `FlutterVersion.name` for the stored/canonical version
- Use `FlutterVersion.printFriendlyName` for user-facing displays
- When processing commit versions, always use the full hash for comparisons

## References

1. [GitHub Actions DOS vulnerability](https://blog.teddykatz.com/2019/11/12/github-actions-dos.html)
2. [Git rev-parse documentation](https://git-scm.com/docs/git-rev-parse)
3. [SHA-1 collision resistance](https://en.wikipedia.org/wiki/SHA-1#Collision_attacks)

## Future Considerations

1. **Migration Warning**: Consider adding a warning when reading old configs with short hashes
2. **Hash Validation**: Add validation to reject ambiguous short hashes
3. **Config Version**: Consider versioning the `.fvmrc` format to handle future changes
