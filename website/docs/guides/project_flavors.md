---
id: project_flavors
title: Project Flavors
sidebar_position: 3
---

You can have multiple Flutter SDK versions configured per project environment or release type. FVM follows the same convention of Flutter and calls this `flavors`.

It allows you to create the following configuration for your project.

```json
{
  "flutterSdkVersion": "stable",
  "flavors": {
    "dev": "beta",
    "staging": "2.0.3",
    "production": "1.22.6"
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
fvm flavor {flavor_name}
```

## View flavors

To list all configured flavors:

```bash
fvm flavor
```

[Learn more about Flutter flavors](https://flutter.dev/docs/deployment/flavors)
