---
id: faq
title: FAQ
---

# FAQ

### Upgrade Flutter Channel

As described in our [Principles](../getting-started/#principles) FVM does not override standard Flutter behavior. Therefore to upgrade a channel you will have to use standard `flutter upgrade`. You can find more about it in the [Running Flutter](../guides/running-flutter) section.

---

### Cannot install latest version of FVM

When running `dart pub global activate fvm`, pub will grab the latest FVM version that is compatible with the installed dart-sdk. Upgrade to the latest version of the Dart, and run the command again. Go to https://dart.dev/get-dart for more information.

---

### How to uninstall FVM

Run command `fvm destroy` to remove FVM from your system.
If you installed using pub run `dart pub global deactivate fvm`, if you used a standalone installation please follow its instructions.

---

### Commands run twice on Windows

This happens due to a pub issue https://github.com/dart-lang/pub/issues/2934. To avoid this issue from happening make sure you PATH is in the following order. [Please read the following](#environment-variables-order-for-windows-in-path).

---

### Invalid kernel binary or invalid sdk hash when running FVM

There are a few reasons this can happen. However it means that the FVM snapshot is not compatible with the Dart version that is installed.

Please do the following:

1. On Windows make sure your env variables are in the following order as described [here](#environment-variables-order-for-windows-in-path).
2. Run `dart pub global deactivate fvm`
3. Run `dart pub global activate fvm`

---

### Command 'pub' not found

If you get `Command 'pub' not found`, then make sure to append `export PATH="$PATH:/usr/lib/dart/bin"` to your `~/.bashrc` (gets reiniated each time you open a bash shell) or `~/.profile` (only read at login) file.

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

### Git not found after install on Windows

Some users may be greeted by this error after installing FVM in a project.

```
Error: Unable to find git in your PATH.
```

This happens because of a security update from git where Git now checks for ownership of the folder trying to ensure that the folder you are using Git in has the same user as the owner as your current user account.
To fix this, we need to mark our repos as safe using the following command:

```
git config --global --add safe.directory '*'
```

Restart your terminals and VS Code after running this command. This should fix the issue

If you don’t want to mark all the repos as safe, then you can mark only the flutter repo as safe by passing the flutter path instead of *

```
git config --global --add safe.directory C:\Users\someUser\flutter\.git\
```
