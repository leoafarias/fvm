---
id: custom_version
title: Custom Flutter Version
sidebar_position: 0
---

You can use custom Flutter versions (forks) within FVM cache.

It is important that you add `custom_` to the folder name, so FVM knows that this is a custom Flutter version.

```bash
#Now you can use the following command
fvm use custom_{version}
```

:::tip
Run `fvm list` to view the cache directory, and the current cached versions.
:::
