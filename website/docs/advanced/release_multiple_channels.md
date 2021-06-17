---
id: release_multiple_channels
title: Release In Multiple Channels
sidebar_position: 2
---

In some cases a Flutter release can show up on multiple channels. FVM will prioritize the channel by stability. Stable > Beta > Dev. Which means any version number will resolve to the most "stable" channel if exists in multiple channels.

For example version `2.2.2` exists in both stable, and beta channels. That means the feature flags they use are different.

```bash
fvm use 2.2.2 # Installs 2.2.2 from stable
```

However if you want to force a version to be installed from a specific channel you can do `fvm install CHANNEL@VERSION`. This looks like the following.

```bash
fvm use 2.2.2@beta # Installs 2.2.2 from beta
```
