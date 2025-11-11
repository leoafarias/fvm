# Install / Permission Issue Archive

Generated on 2025-11-06 to capture GitHub issues (open + closed) referencing install scripts, sudo/permission problems, or "No such file or directory" errors for `leoafarias/fvm`. After the initial download, the dataset was curated so that **only issues directly about the `install.sh` script’s behavior or implementation remain** (documentation-only threads and incidental mentions were removed).

## Search Queries
- `repo:leoafarias/fvm "install.sh"`
- `repo:leoafarias/fvm sudo`
- `repo:leoafarias/fvm "permission denied"`
- `repo:leoafarias/fvm permission` (pages 1-2)
- `repo:leoafarias/fvm "No such file or directory"`

## Contents
- `issue-<number>.json`: raw issue metadata + every comment returned by `gh issue view ... --json ...`
- `manifest.json`: quick index (number, title, state, labels, file path).

## Usage
- Browse with any editor, or query via `jq`, e.g. `jq '.title' issue-699.json`.
- Filter via manifest, e.g. `jq '.[] | select(.state=="open") | .file' manifest.json`.

> Note: only issues matching the queries above **and** focused on the `install.sh` script itself were kept. Run a new search and repeat the export if you need different keywords.
