---
id: basic_commands
title: Basic Commands
sidebar_position: 0
---

## Use

Sets Flutter SDK Version you would like to use in a project.If version does not exist it will ask if you want to install. If you are starting a new project and plan on using fvm flutter create you wil have to use the --force flag

```bash
Usage:
    fvm use {version}

Option:
    -h, --help     Print this usage information.
    -f, --force    Skips Flutter project checks.
    -p, --pin      Pins latest release channel instead of channel itself.
        --flavor   Sets version for a project flavor
```

If you are starting a new project and plan on using `fvm flutter create` you wil have to use the `--force` flag

## Install

Installs Flutter SDK Version. Gives you the ability to install Flutter releases or channels.

```bash
Usage:
    fvm install - # Installs version found in project config
    fvm install {version} - # Installs specific version

Option:
    -h, --help          Print this usage information.
    -s, --skip-setup    Skips Flutter setup after install
```

## Remove

Removes Flutter SDK Version. Will impact any projects that depend on that version of the SDK.

```bash
Usage:
    fvm remove {version}

Option:
    -h, --help     Print this usage information.
        --force    Skips version global check.
```

## List

Lists installed Flutter SDK Versions. Will also print the cache directory used by FVM.

```bash
Usage:
    fvm list

Option:
    -h, --help     Print this usage information.
```

## Releases

View all Flutter SDK releases available for install.

```bash
Usage:
    fvm releases

Option:
    -h, --help     Print this usage information.
```

## Doctor

Shows information about environment, and project configuration.

```bash
Usage:
    fvm doctor

Option:
    -h, --help     Print this usage information.
```
