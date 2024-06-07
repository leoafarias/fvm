---
id: project_flavors
title: Project Flavors
---

# Project Flavors

You can have multiple Flutter SDK versions configured per project environment or release type. FVM follows the same convention of Flutter and calls this `flavors`.

It allows you to create the following configuration for your project.

```json
{
  "flutter": "stable",
  "flavors": {
    "development": "stable",
    "staging": "3.16.9",
    "production": "3.10.3"
  }
}
```

## Pin flavor version

To choose a Flutter SDK version for a specific flavor you just use the `use` command.

```bash
fvm use {version} --flavor {flavor_name}
```

This will pin `version` to `flavor_name`

## Switch flavors

Will get the version configured for the flavor and set as the project version.

```bash
fvm use {flavor_name}
```

## Spwan a command with a flavor version

Will get the version configured for the flavor and use to run a Flutter command.

```bash
fvm flavor {flavor_name} {flutter_command} {flutter_command_args}
```


