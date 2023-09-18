---
id: global_version
title: Global Flutter SDK
sidebar_position: 3
---


You can have the default Flutter version in your machine but still, preserve the dynamic switching. It allows you not to make any changes on how you currently use Flutter but benefit from faster switching and version caching.

To accomplish this FVM provides you a helper command to configure a global version.

```bash
fvm global {version}
```

Now you will be able to do the following.

```bash title="Example"
# Set beta channel as global
fvm global beta

# Check version
flutter --version # Will be beta release

# Set stable channel as global
fvm global stable

# Check version
flutter --version # Will be stable release
```

:::info
After you run the command, FVM will check if the global version is configured in your environment path. If it is not it will provide you with the path that it needs to be configured.
:::