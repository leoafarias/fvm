---
title: Spawn Command
---

# Spawn

The `spawn` command is used to execute Flutter commands using a specific Flutter SDK version.

This command is particularly useful when you need to run a Flutter command (such as `flutter build`) with a version of the SDK different from the one currently active or configured in your project.

## Usage

```bash
> fvm spawn [version] [flutter_command] [flutter_command_args]
```

`[version]`: The Flutter SDK version you want to use for running the command.

`[flutter_command]`: The Flutter command you want to execute.

`[flutter_command_args]`: Any additional arguments you want to pass to the Flutter command.

## Examples

**Running a Build with a Specific SDK Version**:  
To build your Flutter project using version `2.5.0` of the Flutter SDK:

```bash
fvm spawn 2.5.0 flutter build
```

**Running Tests with a Different SDK Version**:  
If you need to run tests using a particular Flutter SDK version:

```bash
fvm spawn 2.2.3 flutter test
```
