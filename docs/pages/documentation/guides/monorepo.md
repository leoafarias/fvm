---
id: monorepo
title: Monorepo support
---

# Monorepo support

FVM ensures all projects in a monorepo use the same Flutter SDK version, preventing compatibility issues and simplifying development. Here's how to set up FVM in common monorepo configurations:

## Melos: Monorepo with a Shared `pubspec.yaml`

A shared `pubspec.yaml` at the monorepo's root is beneficial for projects with common dependencies, ensuring they all adhere to a unified Flutter SDK version.

Melos requires a `pubspec.yaml` at the root of the monorepo. Running `fvm use` at the root of the monorepo will generate a `.fvmrc` file at the root, allowing all packages to use the same Flutter SDK version.

### Automatic Melos Configuration

**New in FVM 3.3.0**: FVM now automatically manages the `sdkPath` configuration in `melos.yaml` when you run `fvm use`. This ensures that all scripts and Melos commands utilize the FVM-managed Flutter SDK version, maintaining consistency across the monorepo.

When you run `fvm use`, FVM will:
- Detect `melos.yaml` in the current directory or parent directories (up to the git root)
- Add or update the `sdkPath` field to point to `.fvm/flutter_sdk`
- Calculate the correct relative path for nested project structures
- Preserve existing non-FVM paths with a warning

### Manual Configuration

If you prefer to manage the configuration manually or want to disable automatic updates:

1. To disable Melos updates for a project:
   ```json
   // .fvmrc
   {
     "flutter": "3.19.0",
     "updateMelosSettings": false
   }
   ```

2. To manually set the SDK path in `melos.yaml`:
   ```yaml
   name: my_workspace
   packages:
     - packages/**
   sdkPath: .fvm/flutter_sdk  # Points to FVM-managed Flutter SDK
   ```

For detailed configuration instructions, refer to the [sdkPath](https://melos.invertase.dev/~melos-latest/configuration/overview#sdkpath) in Melos documentation.

## Project with Subfolders

This setup involves repositories segmented into subfolders, with each housing a distinct Flutter project, and lacking a unified monorepo management tool.

Run `fvm use` at the root folder of the Flutter projects to generate a `.fvmrc` file. Now, each project can use the same Flutter SDK version.