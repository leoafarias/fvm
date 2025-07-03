# JSON API

FVM provides JSON API endpoints for integrating with other tools. All commands support the `--compress` option for compact output.

## Commands

### list

Lists installed Flutter SDK versions.

```bash
fvm api list [--compress] [--skip-size-calculation]
```

**Options:**
- `--compress` - Compact JSON output
- `--skip-size-calculation` - Skip cache size calculation

### releases

Shows available Flutter releases.

```bash
fvm api releases [--compress] [--limit <n>] [--filter-channel <channel>]
```

**Options:**
- `--compress` - Compact JSON output
- `--limit` - Number of releases to return
- `--filter-channel` - Filter by channel (stable, beta, dev)

### context

Returns FVM environment information.

```bash
fvm api context [--compress]
```

### project

Returns project configuration.

```bash
fvm api project [--compress] [--path <path>]
```

**Options:**
- `--compress` - Compact JSON output
- `--path` - Project directory path

## Integration Example

```bash
# Get current project version
fvm api project --compress | jq -r '.project.pinnedVersion'

# List installed versions
fvm api list --compress | jq -r '.versions[].name'
```

### `list`

Lists the installed Flutter SDK versions available locally.

**Usage:**

```bash
fvm api list [options]
```

**Options:**

-  `--compress` (`-c`): Outputs JSON with no whitespace.
-  `--skip-size-calculation` (`-s`): Skips calculating the size of cached versions.

**Response Payload:**

```json
{
  "size": "922.50 MB",
  "versions": [
    {
      "name": "3.19.2",
      "directory": "/path/to/fvm/versions/3.19.2",
      "releaseFromChannel": null,
      "type": "release",
      "binPath": "/path/to/fvm/versions/3.19.2/bin",
      "hasOldBinPath": false,
      "dartBinPath": "/path/to/fvm/versions/3.19.2/bin",
      "dartExec": "/path/to/fvm/versions/3.19.2/bin/dart",
      "flutterExec": "/path/to/fvm/versions/3.19.2/bin/flutter",
      "flutterSdkVersion": "3.19.2",
      "dartSdkVersion": "3.3.0",
      "isSetup": true
    },
    ...
  ]
}
```

### `releases`

Provides a list of available Flutter SDK releases.

**Usage:**

```bash
fvm api releases [options]
```

**Options:**

-  `--compress`: Outputs JSON with no whitespace.
-  `--limit [number]`: Limits the number of releases listed.
-  `--filter-channel [channel]`: Filters the releases by channel. Available channels are `stable`, `beta`, and `dev`.

**Response Payload:**

```json
{
  "versions": [
    ...
    {
      "hash": "0b591f2c82e9f59276ed68c7d4cbd63196f7c865",
      "channel": "beta",
      "version": "3.17.0-0.0.pre",
      "release_date": "2023-11-15T22:44:50.703003Z",
      "archive": "beta/macos/flutter_macos_3.17.0-0.0.pre-beta.zip",
      "sha256": "2937447f814eff2ebf5aba098dfdb059654a0113456f1b22e855403c2ec413df",
      "dart_sdk_arch": "x64",
      "dart_sdk_version": "3.3.0 (build 3.3.0-91.0.dev)",
      "active_channel": false,
      "channelName": "beta",
      "archiveUrl": "https://storage.googleapis.com/flutter_infra_release/releases/beta/macos/flutter_macos_3.17.0-0.0.pre-beta.zip"
    }
  ],
  "channels": {
    "beta": {...},
    "stable": {...}
  }
}
```

### `context`

Returns information about the FVM's current context.

**Usage:**

```bash
fvm api context [options]
```

**Options:**

-  `--compress`: Outputs JSON with no whitespace.

**Response Payload:**

```json
{
  "context": {
    "fvmVersion": "3.0.14",
    "workingDirectory": "/path/to/project",
    "isTest": false,
    "fvmDir": "/path/to/.fvm",
    "gitCache": true,
    "runPubGetOnSdkChanges": true,
    "gitCachePath": "/path/to/.fvm/cache.git",
    "flutterUrl": "https://github.com/flutter/flutter.git",
    "lastUpdateCheck": "2024-03-13T14:46:08.735250Z",
    "updateCheckDisabled": false,
    "privilegedAccess": false,
    "globalCacheLink": "/path/to/.fvm/default",
    "globalCacheBinPath": "/path/to/.fvm/default/bin",
    "versionsCachePath": "/path/to/.fvm/versions",
    "configPath": "/Users/username/Library/Application Support/fvm/.fvmrc",
    "isCI": false,
    "id": "MAIN",
    "args": [
      "api",
      "info"
    ]
  }
}
```

### `project`

Fetches details about the current Flutter project configuration.

**Usage:**

```bash
fvm api project [options]
```

**Options:**

-  `--compress`: Outputs JSON with no whitespace.
-  `--path [path]`: The path to the project. Defaults to the current working directory.

**Response Payload:**

```json
{
  "project": {
    "name": "my_project",
    "config": {
      "flutter": "3.19.2",
      "flavors": {
        "production": "3.19.2",
        "development": "stable"
      }
    },
    "path": "/path/to/project",
    "pinnedVersion": {
      "name": "3.19.2",
      "releaseFromChannel": null,
      "type": "release"
    },
    "activeFlavor": "production",
    "flavors": {
      "production": "3.19.2",
      "development": "stable"
    },
    "dartToolGeneratorVersion": "3.3.0",
    "dartToolVersion": "3.19.2",
    "isFlutter": true,
    "localFvmPath": "/path/to/project/.fvm",
    "localVersionsCachePath": "/path/to/project/.fvm/versions",
    "localVersionSymlinkPath": "/path/to/project/.fvm/versions/3.19.2",
    "gitIgnorePath": "/path/to/project/.gitignore",
    "pubspecPath": "/path/to/project/pubspec.yaml",
    "configPath": "/path/to/project/.fvmrc",
    "legacyConfigPath": "/path/to/project/.fvm/fvm_config.json",
    "hasConfig": true,
    "hasPubspec": true,
    "pubspec": {
      "name": "my_project",
      "version": "0.1.0",
      "publish_to": "none",
      "environment": {
        "sdk": ">=2.17.0 <4.0.0"
      },
      "description": "A new Flutter project.",
      "dependencies": {
        ...
      },
      "dev_dependencies": {
        ...
      },
      "flutter": {
        "uses-material-design": true
      }
    }
  }
}
```
