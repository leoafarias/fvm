---
id: project_flavors
title: Project Flavors
---

# Project Flavors

You can have multiple Flutter SDK versions configured per project environment or release type. FVM follows the same convention as Flutter and calls this `flavors`.

It allows you to create the following configuration for your project.

```json
{
  "flutter": "stable",
  "flavors": {
    "development": "stable",
    "staging": "3.19.0",
    "production": "3.16.0"
  }
}
```

## Pin flavor version

To choose a Flutter SDK version for a specific flavor, you just use the `use` command.

```bash
fvm use {version} --flavor {flavor_name}
```

This will pin `version` to `flavor_name`.

## Switch flavors

This will get the version configured for the flavor and set it as the project version.

```bash
fvm use {flavor_name}
```

## Spawn a command with a flavor version

This will get the version configured for the flavor and use it to run a Flutter command.

```bash
fvm flavor {flavor_name} {flutter_command} {flutter_command_args}
```
