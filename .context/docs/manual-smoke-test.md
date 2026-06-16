# Manual Branch Smoke Test

Use this when an agent needs a quick end-to-end check of the current FVM branch without running the destructive real integration suite.

This smoke test runs the branch CLI through a throwaway project and isolated cache. It uses a local fake Flutter Git remote, so it proves FVM command wiring, git-cache creation, install, project `use`, symlink creation, and `fvm flutter` proxy behavior without cloning the real Flutter repository.

## When To Run

Run this before handoff when changes touch:

- `GitService`
- `FlutterService`
- `EnsureCacheWorkflow`
- install/use/global command behavior
- project reference or SDK symlink behavior

This does not replace `dart test`, `dcm analyze lib`, or the real `fvm integration-test`. It is a fast manual confidence check between unit tests and the full destructive integration suite.

## Safety

The script sets:

- `HOME` to a temp directory
- `FVM_CACHE_PATH` to a temp cache
- `FVM_GIT_CACHE_PATH` to a temp bare git cache
- `FVM_FLUTTER_URL` to a local `file://` Git URL
- `FVM_USE_GIT_CACHE=true`

It should not mutate the user's normal FVM cache or global config. The temp directory is left in place for inspection and printed as `Smoke root`; remove it manually after reviewing.

`FVM_FLUTTER_URL` must be a valid Git URL. Use a `file://` URL for local remotes; a plain filesystem path is rejected by FVM URL validation.

## Command

Run from the repository root:

```bash
set -euo pipefail

FVM_REPO="$(pwd)"
ROOT="$(mktemp -d /tmp/fvm-branch-smoke.XXXXXX)"
FAKE_REMOTE_WORK="$ROOT/flutter_seed"
FAKE_REMOTE_BARE="$ROOT/flutter_remote.git"
CACHE="$ROOT/fvm-cache"
GIT_CACHE="$ROOT/cache.git"
PROJECT="$ROOT/app"
HOME_DIR="$ROOT/home"

mkdir -p \
  "$FAKE_REMOTE_WORK/bin" \
  "$FAKE_REMOTE_WORK/bin/cache/dart-sdk/bin" \
  "$PROJECT" \
  "$HOME_DIR"

cd "$FAKE_REMOTE_WORK"
git init -b stable >/dev/null
git config user.email smoke@fvm.app
git config user.name "FVM Smoke"

printf '3.99.0-smoke\n' > version
printf '#!/usr/bin/env sh\necho "Flutter smoke 3.99.0 on stable"\n' > bin/flutter
printf '#!/usr/bin/env sh\necho "Dart smoke 3.99.0"\n' > bin/dart
printf '#!/usr/bin/env sh\necho "Dart smoke 3.99.0"\n' > bin/cache/dart-sdk/bin/dart
chmod +x bin/flutter bin/dart bin/cache/dart-sdk/bin/dart

git add . >/dev/null
git commit -m 'seed fake flutter' >/dev/null
git clone --bare "$FAKE_REMOTE_WORK" "$FAKE_REMOTE_BARE" >/dev/null 2>&1
git --git-dir="$FAKE_REMOTE_BARE" symbolic-ref HEAD refs/heads/stable

REMOTE_URL="file://$FAKE_REMOTE_BARE"

cd "$PROJECT"
printf 'name: fvm_smoke_app\nenvironment:\n  sdk: ">=3.6.0 <4.0.0"\n' > pubspec.yaml

run_fvm() {
  HOME="$HOME_DIR" \
  FVM_CACHE_PATH="$CACHE" \
  FVM_GIT_CACHE_PATH="$GIT_CACHE" \
  FVM_FLUTTER_URL="$REMOTE_URL" \
  FVM_USE_GIT_CACHE=true \
  dart run "$FVM_REPO/bin/main.dart" --fvm-skip-input "$@"
}

printf '\n== fvm version ==\n'
run_fvm --version

printf '\n== install stable --no-setup ==\n'
run_fvm install stable --no-setup

printf '\n== use stable ==\n'
run_fvm use stable --force --skip-setup --skip-pub-get

printf '\n== fvm flutter --version ==\n'
FLUTTER_OUTPUT="$(run_fvm flutter --version)"
printf '%s\n' "$FLUTTER_OUTPUT"
case "$FLUTTER_OUTPUT" in
  *"Flutter smoke 3.99.0"*) ;;
  *) echo "Unexpected flutter output" >&2; exit 1 ;;
esac

printf '\n== fvm list ==\n'
run_fvm list

printf '\n== project files ==\n'
test -f .fvmrc
test -L .fvm/flutter_sdk
printf '.fvmrc: '
sed -n '1,20p' .fvmrc
printf 'flutter_sdk -> '
readlink .fvm/flutter_sdk

printf '\n== git cache checks ==\n'
test "$(git --git-dir="$GIT_CACHE" rev-parse --is-bare-repository)" = true

HEAD_REF="$(git --git-dir="$GIT_CACHE" symbolic-ref --quiet HEAD)"
printf 'HEAD=%s\n' "$HEAD_REF"
case "$HEAD_REF" in
  refs/heads/*) ;;
  *) echo "Cache HEAD is not a branch" >&2; exit 1 ;;
esac

REFS="$(git --git-dir="$GIT_CACHE" for-each-ref --format='%(refname)')"
printf '%s\n' "$REFS"
if printf '%s\n' "$REFS" | grep -Ev '^(refs/heads/|refs/tags/)' >/dev/null; then
  echo "Unexpected non heads/tags ref in git cache" >&2
  exit 1
fi

FETCH_SPECS="$(git --git-dir="$GIT_CACHE" config --get-all remote.origin.fetch | sort)"
printf 'fetch specs:\n%s\n' "$FETCH_SPECS"
printf '%s\n' "$FETCH_SPECS" | grep -Fqx '+refs/heads/*:refs/heads/*'
printf '%s\n' "$FETCH_SPECS" | grep -Fqx '+refs/tags/*:refs/tags/*'
test "$(git --git-dir="$GIT_CACHE" config --get remote.origin.tagOpt)" = '--no-tags'

if git --git-dir="$GIT_CACHE" config --get remote.origin.mirror >/dev/null; then
  echo "Unexpected mirror config" >&2
  exit 1
fi

git --git-dir="$GIT_CACHE" fsck --connectivity-only >/dev/null

printf '\nSmoke root: %s\n' "$ROOT"
```

## Expected Result

The command must exit `0`.

Expected high-signal output:

- `fvm --version` prints the branch package version.
- `install stable --no-setup` creates the local git cache and installs `stable`.
- `use stable --force --skip-setup --skip-pub-get` updates the throwaway project.
- `fvm flutter --version` prints `Flutter smoke 3.99.0 on stable`.
- `.fvmrc` contains `"flutter": "stable"`.
- `.fvm/flutter_sdk` points to the isolated temp cache.
- `cache.git` is bare.
- `cache.git` `HEAD` is under `refs/heads/`.
- `remote.origin.fetch` contains only:
  - `+refs/heads/*:refs/heads/*`
  - `+refs/tags/*:refs/tags/*`
- `remote.origin.tagOpt` is `--no-tags`.
- `remote.origin.mirror` is absent.
- `git fsck --connectivity-only` passes.

## Cleanup

After inspection:

```bash
rm -rf /tmp/fvm-branch-smoke.<suffix>
```

Use the exact `Smoke root` path printed by the run.

## When To Escalate To Real Integration

Run the real integration workflow instead when you need proof against live Flutter infrastructure, real SDK setup, `flutter doctor`, destructive cleanup, concurrency, or global symlink behavior:

```bash
dart run grinder integration-test
```

That workflow is intentionally slower and can mutate the real FVM cache. See `integration-tests.md` before running it locally.
