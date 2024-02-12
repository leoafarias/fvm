---
id: overview
title: Overview
---

# Overview

FVM helps with the need for consistent app builds by referencing the Flutter SDK version used on a per-project basis. It also allows you to have multiple Flutter versions installed to quickly validate and test upcoming Flutter releases with your apps without waiting for Flutter installation every time.

## Motivation

- We need to have more than one Flutter SDK at a time.
- Testing new SDK features requires switching between [Channels](https://flutter.dev/docs/development/tools/sdk/releases).
- The switch between channels is slow and requires reinstalling every time.
- No way of keeping track of the latest working/used version of the SDK in an app.
- Major Flutter updates require migration of all Flutter apps in the machine.
- Inconsistent development environments between other devs in the team.

## Video Guides & Walkthroughs

You can view a playlist of many Youtube guides & walkthroughs done by the incredible Flutter community in many different languages.

<iframe width="560" height="315" src="https://www.youtube.com/embed/videoseries?list=PLVnlSO6aQelAAddOFQVJNoaRGZ1mMsj2Q" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Principles

We follow these principles when building and adding new features to FVM.

- Always use Flutter tools when interacting with the SDK.
- Do not override any Flutter CLI commands.
- Follow Flutter suggested installation instructions accomplish caching.
- Should extend Flutter behavior and not modify them.
- API should be simple and easy to understand.

## Contributors


<a href="https://github.com/leoafarias/fvm/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=leoafarias/fvm" />
</a>
