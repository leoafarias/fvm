---
id: monorepo
title: Monorepo support
---

# Monorepo support

FVM helps ensure that all projects or packages within a monorepo utilize a consistent Flutter SDK version. This consistency is crucial for avoiding compatibility issues and streamlining the development process. Here's how you can leverage FVM effectively in two common monorepo setups:

## Melos: Monorepo with a Shared `pubspec.yaml`

A shared `pubspec.yaml` at the monorepo's root is beneficial for projects with common dependencies, ensuring they all adhere to a unified Flutter SDK version.

Melos requires a `pubspec.yaml` at the root of the monorepo. Running `fvm use` at the root of the monorepo will generate a `.fvmrc` file at the root, allowing all packages to use the same Flutter SDK version.

Specify the Flutter SDK version in `melos.yaml`. This configuration ensures that all scripts and Melos commands utilize the designated Flutter SDK version, maintaining consistency across the monorepo.

For detailed configuration instructions, refer to the [sdkPath](https://melos.invertase.dev/~melos-latest/configuration/overview#sdkpath) in Melos documentation.

## Project with Subfolders

This setup involves repositories segmented into subfolders, with each housing a distinct Flutter project, and lacking a unified monorepo management tool.

Run `fvm use` at the root folder of the Flutter projects to generate a `.fvmrc` file. Now, each project can use the same Flutter SDK version.