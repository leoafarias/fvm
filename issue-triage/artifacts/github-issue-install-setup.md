## Summary

`fvm install` should run setup by default to match `fvm use` behavior and improve user experience.

**Target Version:** v5.0 (behavior change)

## Current Behavior (v4)

```bash
# No setup runs by default
fvm install 3.19.0

# Need to pass --setup flag
fvm install 3.19.0 --setup
```

This causes "Need setup*" warnings in `fvm list` and confuses users who expect installed SDKs to be ready to use.

## Proposed Behavior (v5)

```bash
# Setup runs by default (NEW)
fvm install 3.19.0

# Equivalent to --setup being default
fvm install 3.19.0 --setup

# Opt out with --no-setup (NEW)
fvm install 3.19.0 --no-setup
```

## Why This Matters

1. **Consistency** - `fvm use` already runs setup by default
2. **User expectations** - "Install" implies "ready to use"
3. **Reduces confusion** - No more "Need setup*" messages for beginners
4. **Better UX** - One less step to remember

## User Impact

**Positive:**
- New users get working SDKs immediately
- Consistent behavior across commands
- Less documentation needed

**Negative:**
- Behavior change for scripts that rely on fast caching
- Batch installs become slower (runs setup N times)
- CI/CD pipelines may need to add `--no-setup` for performance

**Migration:** Users who want old behavior simply add `--no-setup` flag.

## Implementation Tasks

### 1. Update `lib/src/commands/install_command.dart`

**Current code:**
```dart
argParser
  ..addFlag(
    'setup',
    abbr: 's',
    help: 'Downloads SDK dependencies after install',
    defaultsTo: false,  // Currently false
    negatable: false,
  )
```

**Updated code:**
```dart
argParser
  ..addFlag(
    'setup',
    abbr: 's',
    help: 'Downloads SDK dependencies after install (default: true)',
    defaultsTo: true,   // CHANGE: Now true by default
    negatable: true,    // CHANGE: Allow --no-setup to opt out
  )
```

**Logic stays the same:**
```dart
final setup = boolArg('setup');

if (setup) {
  await setupFlutter(cacheVersion);
}
```

### 2. Update Documentation

**File: `docs/pages/documentation/guides/basic-commands.mdx`**

Update the install section:

```markdown
## install

Downloads and caches a Flutter SDK version for future use. **Runs setup by default to ensure SDK is ready to use.**

### Options

- `-s, --setup` - Downloads SDK dependencies after install (default: true)
- `--no-setup` - Skip downloading SDK dependencies for faster caching

### Examples

```bash
# Install with setup (default behavior)
fvm install 3.19.0

# Skip setup for faster caching
fvm install 3.19.0 --no-setup

# Install from project config
fvm install
```
```

**File: `docs/pages/documentation/guides/quick-reference.md`**

Update the table:

```markdown
| Option | Commands | Purpose |
|--------|----------|---------|
| `--setup` | install | Run Flutter setup (default: ON) |
| `--no-setup` | install, use | Skip setup for faster caching |
```

### 3. Update CLI Help Text

The help text is automatically generated from the `help` parameter in the argParser, so updating step 1 covers this.

### 4. Add CHANGELOG Entry

```markdown
## [5.0.0] - YYYY-MM-DD

### Changed
- **BEHAVIOR CHANGE:** `fvm install` now runs setup by default to ensure SDKs are immediately usable
- `--setup` flag is now the default behavior for `fvm install`
- Add `--no-setup` flag to skip setup and cache quickly (replaces old default behavior)
- This matches the behavior of `fvm use` for consistency

### Migration
- If your scripts rely on `fvm install` being fast (no setup), add `--no-setup` flag
- Example: `fvm install 3.19.0 --no-setup`
```

### 5. Testing

**Test cases to verify:**

1. **Default behavior:**
   ```bash
   fvm install 3.19.0
   # Verify: Setup runs, SDK is ready
   fvm list
   # Verify: No "Need setup*" message
   ```

2. **Explicit --setup (should be same as default):**
   ```bash
   fvm install 3.16.0 --setup
   # Verify: Setup runs, SDK is ready
   ```

3. **Opt out with --no-setup:**
   ```bash
   fvm install 3.13.0 --no-setup
   # Verify: Setup does NOT run
   fvm list
   # Verify: Shows "Need setup*"
   ```

4. **Backward compatibility:**
   ```bash
   # Existing project with .fvmrc
   fvm install
   # Verify: Setup runs by default
   ```

5. **Batch installs:**
   ```bash
   fvm install 3.19.0 --no-setup
   fvm install 3.16.0 --no-setup
   fvm install 3.13.0 --no-setup
   # All should skip setup for fast caching
   ```

## Related

- Discussion #950: "Why does my beta need a setup?"

## Acceptance Criteria

- [ ] `lib/src/commands/install_command.dart` updated with `defaultsTo: true` and `negatable: true`
- [ ] Documentation updated in `basic-commands.mdx`
- [ ] Documentation updated in `quick-reference.md`
- [ ] CHANGELOG.md entry added
- [ ] All 5 test cases pass
- [ ] No breaking changes to existing `--setup` flag (still works)
- [ ] `--no-setup` flag works to opt out
