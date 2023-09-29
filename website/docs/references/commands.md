---

id: basic_commands
title: Commands
sidebar_position: 0

---

# Introduction

Get familiar with the primary commands you'll use in FVM - Flutter Version Management. Each command performs a specific function enabling you to manage different Flutter SDK versions in your projects. We'll walk you through each command, describe its purpose, explain how you should use it, and anticipate any issues you might encounter. Don't worry, we've got your back!

## Using a Specific Flutter SDK Version

In FVM, using a specific Flutter SDK version on a project is a breeze.

```bash
Usage:
    fvm use {version}

Option:
    -h, --help     Print this usage information.
    -f, --force    Skips Flutter project checks.
    -p, --pin      Pins latest release channel instead of channel itself.
        --flavor   Sets version for a project flavor
```

Remember, you'll need the `--force` flag if you're starting a new project with `fvm flutter create`.

**Troubleshooting**: If the version does not exist, FVM will ask if you want to install it.


## Installing Flutter SDK Versions

Want to adopt a new Flutter release or channel? You're just a command away!

```bash
Usage:
    fvm install - # Installs version found in project config
    fvm install {version} - # Installs specific version 

Option:
    -h, --help            Print this usage information.
    -s, --skip-setup      Skips Flutter setup after install
```

**Troubleshooting**: Make sure your project config contains the right version. If you're installing a specific version, ensure it exists.

## Removing Flutter SDK Versions

Time to declutter your project from old Flutter SDK versions? Use the following command, but use it wisely.

```bash
Usage:
    fvm remove {version}

Option:
    -h, --help     Print this usage information.
        --force    Skips version global check.
```

**Warning**: Be careful when removing versions. Any projects depending on the version you're removing will be impacted.

## Listing Installed Flutter SDK Versions

Want to take stock of your installed versions? FVM has you covered.

```bash
Usage:
    fvm list

Option:
    -h, --help     Print this usage information.
```

**Bonus**: This command also prints the cache directory used by FVM!

## Checking Available Flutter SDK Releases 

Know what's cooking in the Flutter world with just one command!

```bash
Usage:
    fvm releases

Option:
    -h, --help     Print this usage information.
```

**Tip**: Always stay updated with the latest releases!

## Diagnosing Your Setup

Want a quick overview of your environment and project setup?

```bash
Usage:
    fvm doctor

Option:
    -h, --help     Print this usage information.
```

**Pro Tip**: Always run `fvm doctor` if you're experiencing issues. It can help to highlight potential problems!

---

Navigating through FVM commands might seem overwhelming at first, but once you get started, you'll see how these commands make version management a breeze. Remember, each new command you learn is a step towards mastering FVM!