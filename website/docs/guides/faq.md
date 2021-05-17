---
id: faq
title: FAQ
sidebar_position: 4
---

### Upgrade Flutter Channel

As described in our [Principles](../getting_started/overview/#principles) FVM does not override standard Flutter behavior. Therefore to upgrade a channel you will have to use standard `flutter upgrade`. You can find more about it in the [Running Flutter](/docs/guides/running_flutter) section.

---

### Monorepo support

Suppose you have a nested package(s) that you want to share the same Flutter version. You can set up the FVM config at the root of the monorepo.

FVM will do an ancestor look-up to find the config and use it as the default.

---

### Cannot install latest version of FVM

When running `pub global activate fvm`, pub will grab the latest FVM version that is compatible with the installed dart-sdk. Upgrade to the latest version of the Dart, and run the command again. Go to https://dart.dev/get-dart for more information.

---

### Commands run twice on Windows

This happens due to a pub issue https://github.com/dart-lang/pub/issues/2934. To avoid this issue from happening make sure you PATH is in the following order. [Please read the following](#environment-variables-order-for-windows-in-path).

---

### Invalid kernel binary or invalid sdk hash when running FVM

There are a few reasons this can happen. However it means that the FVM snapshot is not compatible with the Dart version that is installed.

Please do the following:

1. On Windows make sure your env variables are in the following order as described [here](#environment-variables-order-for-windows-in-path).
2. Run `dart pub cache repair`

---

### Environment variables order for Windows in PATH

Flutter comes with Dart embedded. Because of that you can find some conflicts when running standalone Dart and Flutter together. Here is a suggestion of what we found to be the correct order of dependencies to avoid issues.

1. Pub Cache for global packages
2. Dart SDK (if installed outside of Flutter)
3. Flutter SDK

It should look like this.

```
C:\Users\<user>\AppData\Roaming\Pub\Cache\bin
C:\src\flutter\bin\cache\dart-sdk\bin
C:\src\flutter\bin
```
