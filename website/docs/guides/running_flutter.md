---
id: running_flutter
title: Running Flutter
sidebar_position: 2
---

There are a few ways you can interact with the Flutter SDK setup. These will depend primarily on preference.

## Proxy Commands

You are able to proxy any `flutter` or `dart` commands to the configured version by adding `fvm` in front of it.

### Flutter

```bash
# Use
> fvm flutter {command}
# Instead of
> flutter {command}
```

### Dart

```bash
# Use
> fvm dart {command}
# Instead of
> dart {command}
```

:::tip

Configure the following alias for a shorthand version of the command

```bash
# aliases
f="fvm flutter"
d="fvm dart"

# Now you can use
f run
```

:::

### Benefits

- Find relative project configurations.
- Monorepo compatibility.
- Fallback to `global` configured version or `PATH` configured.

### Routing

When proxying commands, `FVM` will look for an sdk in the following order.

1. Project
2. Ancestor directory
3. Global (Set through FVM)
4. Environment (Flutter version configured on `PATH`)

## Call SDK Directly

Versions installed by FVM are standard Flutter SDK installs. That means you are able to call them directly without proxying through FVM.

Using the symlink will dynamically call the configured version for the project.

```bash
# flutter run
.fvm/flutter_sdk/bin/flutter run
```

:::tip

Configure the following alias to call the relative project version, without the need to proxy.

```bash
fv=".fvm/flutter_sdk/bin/flutter"
```

:::

## Spawn Command

Spawns a command on any installed Flutter SDK.

```bash
fvm spawn {version}
```

**Example**

The following will run `flutter analyze` on the `master` channel

```bash
fvm spawn master analyze
```
