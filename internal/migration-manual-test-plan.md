# FVM manual migration test plan (legacy git cache + SDK references)

Goal: validate that a legacy (non-bare) git cache and any SDK references are migrated correctly, and that this branch still operates the cache and SDKs after migration.

## Variables (set once)

```bash
# Use an isolated cache so we do not touch your global ~/.fvm
export FVM_CACHE_PATH="/Users/leofarias/Forks/fvm/.conductor/montevideo/.context/tmp/fvm-migration-cache"
export FVM_USE_GIT_CACHE=true
```

## Step 0 - Preflight

```bash
git --version
 dart --version
 fvm --version
```

Expected:
- git and dart available
- fvm prints a version (latest release)

## Step 1 - Clean slate

```bash
rm -rf "$FVM_CACHE_PATH"
mkdir -p "$FVM_CACHE_PATH"
```

Expected:
- `$FVM_CACHE_PATH` exists and is empty

## Step 2 - Seed legacy cache (pre-4.0.2)

Use a version prior to 4.0.2 to create a non-bare git cache.

```bash
# Legacy FVM (non-bare git cache)
dart pub global activate fvm 4.0.1
fvm --version
```

Pick versions:
- latest stable (channel)
- latest beta (channel)
- one stable release (not a channel)

Recommended way to select versions:

```bash
# Latest stable channel
fvm api releases --filter-channel stable --limit 1 --compress

# Latest beta channel
fvm api releases --filter-channel beta --limit 1 --compress

# Latest 2 stable releases (use the 2nd one as a "release" version)
fvm api releases --filter-channel stable --limit 2 --compress
```

Install the three versions (examples only; replace with real versions):

```bash
fvm install stable
fvm install 3.xx.y
fvm install beta
```

Expected:
- `$FVM_CACHE_PATH/versions/` contains stable, the release version, and beta
- `$FVM_CACHE_PATH/cache.git` exists and is a non-bare repo

Verify legacy cache state:

```bash
git -C "$FVM_CACHE_PATH/cache.git" config --bool core.bare
```

Expected:
- `false`

Verify alternates files exist (created by --reference clones):

```bash
find "$FVM_CACHE_PATH/versions" -path '*/.git/objects/info/alternates' -print -exec cat {} \;
```

Expected:
- Alternates file exists for each installed version
- Contents point to legacy cache path (includes `.git/objects` in path)

## Step 3 - Run this branch to trigger migration

The migration logic lives on this branch (not in published FVM releases).
From the repo root:

```bash
dart pub get

# Trigger EnsureCache -> ensureBareCacheIfPresent -> _migrateCacheCloneToMirror
FVM_CACHE_PATH="$FVM_CACHE_PATH" FVM_USE_GIT_CACHE=true \
  dart run bin/main.dart install stable
```

Expected migration log messages:
- `Migrating cache clone to bare mirror...`
- `Creating bare mirror from local clone...`
- `Legacy cache migrated to bare mirror successfully!`
- `Updated alternates for <version> -> .../cache.git/objects` (one per installed version)

> **Note:** A warning `Failed to setup local cache. Falling back to git clone.`
> may appear after migration if `updateLocalMirror()` fails on the freshly
> converted bare repo. This does not affect migration correctness.

Verify migrated cache state:

```bash
git -C "$FVM_CACHE_PATH/cache.git" config --bool core.bare
```

Expected:
- `true`

Verify alternates were rewritten to bare mirror path:

```bash
find "$FVM_CACHE_PATH/versions" -path '*/.git/objects/info/alternates' -print -exec cat {} \;
```

Expected:
- Alternates files still exist
- Contents now point to `.../cache.git/objects` (no `/.git/` in the path)

Verify repository integrity:

```bash
git -C "$FVM_CACHE_PATH/cache.git" fsck --connectivity-only
```

Expected:
- No errors (dangling commits are normal for a bare mirror converted from a clone)

Verify list still works:

```bash
FVM_CACHE_PATH="$FVM_CACHE_PATH" FVM_USE_GIT_CACHE=true \
  dart run bin/main.dart list
```

Expected:
- list shows the three cached versions and cache path

## Step 4 - Verify SDKs execute

```bash
"$FVM_CACHE_PATH/versions/stable/bin/flutter" --version
"$FVM_CACHE_PATH/versions/3.xx.y/bin/flutter" --version
"$FVM_CACHE_PATH/versions/beta/bin/flutter" --version
```

Expected:
- Each prints Flutter version info and exits 0

## Cleanup (optional)

```bash
rm -rf "$FVM_CACHE_PATH"
```

Expected:
- test cache removed
