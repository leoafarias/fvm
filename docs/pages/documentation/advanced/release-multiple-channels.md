---
id: release_multiple_channels
title: Release In Multiple Channels
---

# Release In Multiple Channels

Sometimes a Flutter version exists in multiple channels. FVM prioritizes the most stable channel: **stable > beta > dev**.

## Example

Version `2.2.2` exists in both stable and beta channels:

```bash
# Installs from stable channel (default)
fvm use 2.2.2
```

## Force Specific Channel

To install from a specific channel, use `@channel`:

```bash
# Install from beta channel
fvm use 2.2.2@beta
```
