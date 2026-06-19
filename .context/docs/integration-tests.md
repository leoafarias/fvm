# FVM Real Integration Test Suite

`fvm integration-test` is the protected real-world guardrail for FVM. It is intentionally separate from the fast mocked Dart suite: it performs real network calls, real Git operations, real Flutter SDK installs, real setup, symlink checks, cache recovery, and destructive cleanup scenarios.

## Command Surface

```bash
# Run the real integration workflow.
fvm integration-test

# Remove temporary integration artifacts only.
fvm integration-test --cleanup-only
```

The command currently exposes only `--cleanup-only`. It does not provide `--fast`, `--phase`, `--test`, or `--list-phases`.

## Trimmed Guardrails

The trimmed suite keeps recipes that prove behavior the fast fake layer cannot prove. Labels in the runner use `// REAL INTEGRATION` for these guardrails.

### Phase 1: Network Release Metadata
- Real releases network fetch through the production release client.

### Phase 2: Real Installation Workflows
- Real channel clone/install.
- Real Git commit clone/install.

### Phase 3: Project Lifecycle
- Real `fvm use` workflow with project config and symlink validation.

### Phase 4: SDK Validation
- Real `fvm flutter doctor` through an installed and set up SDK.

### Phase 5: API Release Smoke
- Real API releases smoke test, unless folded into the Phase 1 network check.

### Phase 6: Recovery
- Corrupted-cache recovery.
- Git clone fallback with an isolated Git cache.

### Phase 7: Destructive Cache Cleanup
- Destroy command followed by reinstall validation.

### Phase 8: Concurrency
- Concurrent access/install safety over real installed versions.

### Phase 9: Global Symlink
- Global version setting and symlink validation.

## What Was Cut

The fast mocked test layer already covers command parsing, config-only flows, and fake SDK plumbing. The real integration runner should not duplicate those imitation checks.

Cut recipes include help/version/list, remove/doctor without real SDK validation, dart/spawn/exec/flavor command plumbing, API list/project/context, fork add/list/remove, config get/set, invalid version/command, state recounting, and PATH log-only validation.

## Environment And Safety

The integration workflow is slow and can be destructive to the real FVM cache.

Requirements:
- Network access to Flutter release metadata and Git remotes.
- Git installed and available on `PATH`.
- Disk space for Flutter SDK clones and setup artifacts.
- Symlink permissions for global and project SDK links.

Expected local cost:
- Duration: 10-30 minutes depending on network and disk.
- Disk: several GB during SDK clone/setup.
- Network: real Flutter repository and release metadata traffic.

Run it locally only when you explicitly intend to exercise the real cache. CI jobs named `integration-test` and `migration-test` are the normal full proof path for pull requests.

## Maintenance

When changing the runner:
- Keep real guardrails labeled with `// REAL INTEGRATION`.
- Preserve install dependency order. Later tests may reuse SDKs installed in earlier phases.
- Do not remove borderline real recipes just because they look slow.
- Keep the summary generated from runtime counters instead of hardcoded test counts.
- Update this file whenever the kept integration guardrails change.
