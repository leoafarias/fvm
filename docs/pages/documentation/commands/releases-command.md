---
title: Releases Command
---

# Releases

The `releases` command in FVM (Flutter Version Management) allows you to view all available Flutter SDK releases, making it easier to choose which version to install or switch to. This command is particularly helpful for staying updated with the latest releases and understanding the Flutter release landscape.

## Usage

```bash
> fvm releases [options]
```

## Options

- `-c, --channel [channel_name]`: Filter the releases by a specific channel (e.g., `stable`, `beta`, `dev`). If no channel is specified, it defaults to showing releases from the `stable` channel.

## Examples

**Viewing All Releases**:  
To view all available Flutter SDK releases:

```bash
fvm releases
```

**Filtering by Channel**:  
To view only the releases from the `beta` channel:

```bash
fvm releases --channel beta
```
