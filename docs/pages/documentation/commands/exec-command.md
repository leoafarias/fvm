---
title: Exec Command
---

## Exec

The `exec` command in FVM is designed to execute scripts or commands using the Flutter SDK version configured for your project. This command is particularly useful for ensuring that the correct version of the Flutter SDK is used for various scripts and operations in a project-specific context.

## Usage

```bash
> fvm exec <command> [arguments]
```

`<command>`: The command or script you want to execute using the Flutter SDK.

`[arguments]`: Any additional arguments you want to pass to the command.


## Examples

**Running a Flutter Command**:  
To run a command (like `melos bootstrap`) using the project's Flutter SDK version:

```bash
fvm exec melos bootstrap
```

**Running a Script**:  
If you have a script that should be run with the project's Flutter SDK, you can execute it like this:

```bash
fvm exec path/to/script.sh
```
