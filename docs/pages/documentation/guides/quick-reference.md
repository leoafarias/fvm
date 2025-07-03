---
id: quick-reference
title: Quick Reference
---

# FVM Quick Reference

## Essential Commands

| Command | Description | Example |
|---------|-------------|---------|
| `fvm use [version]` | Set project SDK version | `fvm use 3.19.0` |
| `fvm install [version]` | Download SDK version | `fvm install stable` |
| `fvm list` | Show installed versions | `fvm list` |
| `fvm global [version]` | Set system default | `fvm global 3.19.0` |
| `fvm flutter [cmd]` | Run Flutter commands | `fvm flutter doctor` |
| `fvm dart [cmd]` | Run Dart commands | `fvm dart pub get` |

## Version Formats

| Format | Example | Description |
|--------|---------|-------------|
| Release | `3.19.0` | Specific version number |
| Channel | `stable` | Latest from channel |
| Commit | `fa345b1` | Git commit hash |
| Fork | `myco/stable` | Custom repository |

## Common Options

| Option | Commands | Purpose |
|--------|----------|---------|
| `--force` | use, global | Skip validation |
| `--pin` | use | Pin channel version |
| `--flavor` | use | Set flavor version |
| `--setup` | install | Run Flutter setup |
| `--skip-pub-get` | use, install | Skip dependencies |

## Workflows

### New Project Setup
```bash
cd myproject
fvm use 3.19.0
```

### Switch Versions
```bash
fvm use 3.16.0 --force
```

### Test Multiple Versions
```bash
fvm spawn 3.19.0 test
fvm spawn 3.16.0 test
```

### Custom Fork
```bash
fvm fork add myco https://github.com/myco/flutter.git
fvm use myco/stable
```

## File Structure

```
myproject/
├── .fvm/
│   ├── flutter_sdk → ../../../.fvm/versions/3.19.0
│   └── fvm_config.json
├── .fvmrc
└── .gitignore (updated)
```

## Environment Variables

- `FVM_CACHE_PATH` - Custom cache directory
- `FVM_GIT_CACHE_PATH` - Git cache location
- `FVM_FLUTTER_URL` - Custom Flutter repo

## Tips

- Use `fvm doctor` to troubleshoot issues
- Add `.fvm/flutter_sdk` to `.gitignore`
- Commit `.fvmrc` for team consistency
- Use `--skip-setup` for faster switching
- Enable git cache for faster installs