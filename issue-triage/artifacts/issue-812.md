# Issue #812: How should I configure FVM so global/project versions coexist?

## Metadata
- **Reporter**: @maxfrees
- **Created**: 2025-01-14
- **Issue Type**: support question
- **URL**: https://github.com/leoafarias/fvm/issues/812

## Summary
User asked how to configure FVM so the global version is used by default, while projects respect their `.fvmrc` version.

## Validation & Guidance
- `fvm global <version>` sets the default symlink (`~/.fvm/default/bin`). Add this directory to PATH.
- Inside a project, `fvm use <version>` creates `.fvmrc` and `.fvm/` symlink; `fvm flutter` or IDE integrations use the project version.
- Documentation already covers this: see `docs/documentation/guides/global-configuration.mdx` and `basic-commands.mdx`.

## Recommendation
Respond with instructions and close as support; no code change required.

## Classification Recommendation
- Folder: `resolved/`
