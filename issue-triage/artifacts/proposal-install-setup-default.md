# Proposal: Run setup by default on `fvm install`

## Problem Statement

Currently, `fvm install` downloads and caches a Flutter SDK but does not run setup by default. This leads to confusion when users try to use the SDK and see "Need setup*" in `fvm list`.

**Current behavior:**
- `fvm install <version>` - Downloads SDK, **no setup** (need `--setup` flag)
- `fvm use <version>` - Downloads SDK (if needed) and **runs setup by default** (unless `--skip-setup`)

This inconsistency causes user confusion, as seen in:
- Discussion #950: User installed beta channel and was confused why setup was needed

## Proposal

Change `fvm install` to run setup by default, making behavior consistent with `fvm use`.

**Proposed behavior:**
```bash
# Setup runs by default
fvm install 3.19.0

# Skip setup if needed (new flag)
fvm install 3.19.0 --skip-setup
```

## Benefits

1. **Better UX** - SDKs are immediately usable after install
2. **Consistency** - Both `install` and `use` behave the same way
3. **Matches user expectations** - "Install" implies "ready to use"
4. **Reduces confusion** - No more "Need setup*" messages for beginners
5. **Simpler mental model** - One less thing to remember

## Drawbacks

1. **Performance** - Batch installs become slower (setup runs N times)
2. **Breaking change** - Existing scripts/CI that rely on fast caching may break
3. **Different semantics** - Some users treat `install` as "cache only"

## Implementation

### Code Changes

1. **Update `install_command.dart`:**
   ```dart
   argParser
     ..addFlag(
       'setup',
       abbr: 's',
       help: 'Downloads SDK dependencies after install',
       defaultsTo: true,  // CHANGE: was false
       negatable: true,   // CHANGE: allow --no-setup
     )
   ```

2. **Update logic:**
   ```dart
   if (setup) {
     await setupFlutter(cacheVersion);
   }
   ```

3. **Add deprecation warning (optional for v4, required for v5):**
   - If user has scripts using `fvm install` without setup, warn them
   - Consider adding `--skip-setup` as the new flag

### Documentation Updates

1. Update [basic-commands.mdx](docs/pages/documentation/guides/basic-commands.mdx) - install section
2. Update [quick-reference.md](docs/pages/documentation/guides/quick-reference.md)
3. Update CLI help text
4. Add migration note if this is a breaking change

### Testing

1. Test `fvm install <version>` runs setup by default
2. Test `fvm install <version> --skip-setup` skips setup
3. Test `fvm install <version> --no-setup` skips setup (if using negatable)
4. Test backward compatibility with existing projects

## Alternative Solutions

### Option 1: Keep current behavior, improve messaging
```bash
$ fvm install beta
✓ Flutter SDK cached successfully

⚠ SDK requires setup before use. Run:
  fvm use beta              # To set up and use in current project
  fvm install beta --setup  # To set up now without using
```

**Pros:**
- No breaking changes
- Preserves current semantics
- Still improves UX through better communication

**Cons:**
- Doesn't solve the inconsistency
- Users still need an extra step

### Option 2: Add a config option
```yaml
# .fvmrc or global config
setupOnInstall: true  # default: false
```

**Pros:**
- User can choose preferred behavior
- No breaking changes for existing users

**Cons:**
- More complexity
- Still inconsistent behavior out of the box

### Option 3: Prompt on first use
```bash
$ fvm install beta
✓ Flutter SDK cached

? Run setup now? (Y/n)
```

**Pros:**
- User chooses at the right moment
- Educational for new users

**Cons:**
- Bad for CI/automation
- Adds friction to the workflow

## Recommendation

**For v4:** Implement **Option 1** (improve messaging) as a quick win, low risk

**For v5:** Implement **Main Proposal** (setup by default) as a breaking change with proper migration guide

## Migration Path (if implementing main proposal)

### For v4.x (prepare for change)
1. Add `--skip-setup` flag alongside `--setup`
2. Add deprecation warning when neither flag is used
3. Document the upcoming change

### For v5.0 (implement change)
1. Change `setup` default to `true`
2. Make `--setup` deprecated (it's now default)
3. Use `--skip-setup` to opt out
4. Update all documentation

## Related Issues/Discussions

- Discussion #950: "Why does my beta need a setup?"
- Related to: Consistency between commands

## Questions for Discussion

1. Should this be v4 or v5?
2. Do we want to add a global config option?
3. What's the migration timeline if we make this breaking?
4. Should we keep `--setup` flag for backward compat (even if it's now default)?
