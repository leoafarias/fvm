---
id: tools
title: Tools
sidebar_position: 4
---

There are a few tools that make it easier to implement or use FVM in your workflow. Below is a non-exhaustive list. If there is a tool which is not listed feel free to [open a pull-request](https://github.com/leoafarias/fvm/pulls) with it.

## Desktop Apps

### [Sidekick](https://github.com/leoafarias/sidekick)

Sidekick is an app that provides a simple desktop interface to tools that enhance Flutter development experience to make it even more delightful.

## Github Actions

### [fvm-config-action](https://github.com/kuhnroyal/flutter-fvm-config-action)

An action that parses an FVM config file into environment variables which can then be used to configure the https://github.com/subosito/flutter-action.

## Codemagic CI

Codemagic now has built-in support for using a FVM config file to select the Flutter version used to build a workflow. More details on how to use this feature can be found in the [Codemagic documentation for the Workflow Editor](https://docs.codemagic.io/flutter-configuration/flutter-projects/#setting-the-flutter-version) and when [using a YAML file](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/#setting-the-flutter-version).

## Docker Images

### [Official Images](https://github.com/leoafarias/fvm/tree/main/.docker)

We have some official Docker images which can be a starting point for customization.

### [daniellampl/flutter-fvm](https://hub.docker.com/r/daniellampl/flutter-fvm)

Allows you to build your mobile #flutter applications using fvm (Flutter Version Management) inside a Docker container 🐳
