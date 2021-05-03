---
id: overview
title: Overview
sidebar_position: 0
---

FVM helps with the need for consistent app builds by referencing the Flutter SDK version used on a per-project basis. It also allows you to have multiple Flutter versions installed to quickly validate and test upcoming Flutter releases with your apps without waiting for Flutter installation every time.

## Motivation

- We need to have more than one Flutter SDK at a time.
- Testing new SDK features requires switching between [Channels](https://flutter.dev/docs/development/tools/sdk/releases)
- The switch between channels is slow and requires reinstalling every time.
- No way of keeping track of the latest working/used version of the SDK in an app.
- Major Flutter updates require migration of all Flutter apps in the machine.
- Inconsistent development environments between other devs in the team.

## Principles

We follow these principles when building and adding new features to FVM.

- Always use Flutter tools when interacting with the SDK
- Do not override any Flutter CLI commands.
- Follow Flutter suggested installation instructions accomplish caching.
- Should extend Flutter behavior and not modify them.
- API should be simple and easy to understand.
