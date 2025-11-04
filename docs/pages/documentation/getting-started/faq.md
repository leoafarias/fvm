---
id: faq
title: FAQ
---

# FAQ

## Upgrade Flutter Channel

As described in our [Principles](https://fvm.app/#principles), FVM does not override standard Flutter behavior. Therefore, to upgrade a channel, you will have to use the standard `flutter upgrade`. You can find more about it in the [Running Flutter](../guides/running-flutter) section.

---

## flutter and dart commands not found

If `fvm flutter` or `fvm dart` commands are not working:

1. Make sure FVM is properly installed and in your PATH
2. Ensure you have a Flutter version configured in your project (`fvm use <version>`)
3. Check that the `.fvm` directory exists in your project

---

## How does FVM find the Flutter version to use?

FVM searches for the Flutter SDK in this order:

1. Project `.fvmrc` file
2. Ancestor directory `.fvmrc` files
3. Global version (set with `fvm global`)
4. System PATH Flutter installation

---

## Cannot install the latest version of FVM

When running `dart pub global activate fvm`, pub will grab the latest FVM version that is compatible with the installed dart-sdk. Upgrade to the latest version of Dart, and run the command again. Go to [get dart](https://dart.dev/get-dart) for more information.

---

## How to uninstall FVM

**Install script (macOS/Linux):**
```bash
./install.sh --uninstall
```

**Homebrew:**
```bash
brew uninstall fvm
brew untap leoafarias/fvm
```

**Pub:**
```bash
dart pub global deactivate fvm
```

**Chocolatey (Windows):**
```bash
choco uninstall fvm
```

**Remove cached Flutter versions (optional):**
```bash
fvm destroy
```

---

## Commands run twice on Windows

This happens due to a pub issue [dart-lang:2934](https://github.com/dart-lang/pub/issues/2934). To avoid this issue from happening, make sure your PATH is in the following order. [Please read the following](#environment-variables-order-for-windows-in-path).

---

## Invalid kernel binary or invalid SDK hash when running FVM

There are a few reasons this can happen. However, it means that the FVM snapshot is not compatible with the Dart version that is installed.

Please do the following:

1. On Windows, make sure your environment variables are in the following order as described [here](#environment-variables-order-for-windows-in-path).
2. Run `dart pub global deactivate fvm`.
3. Run `dart pub global activate fvm`.

---

## Command 'pub' not found

If you get `Command 'pub' not found`, then make sure to append `export PATH="$PATH:/usr/lib/dart/bin"` to your `~/.bashrc` (gets reinitiated each time you open a bash shell) or `~/.profile` (only read at login) file.

---

## Environment variables order for Windows in PATH

Flutter comes with Dart embedded. Because of that, you can find some conflicts when running standalone Dart and Flutter together. Here is a suggestion of what we found to be the correct order of dependencies to avoid issues.

1. Pub Cache for global packages
2. Dart SDK (if installed outside of Flutter)
3. Flutter SDK

It should look like this:

```bash
C:\Users\<user>\AppData\Roaming\Pub\Cache\bin
C:\src\flutter\bin\cache\dart-sdk\bin
C:\src\flutter\bin
```

## Git not found after install on Windows

If you see this error even though `git --version` works, Git 2.35.2+ is blocking the Flutter cache directory. Follow the detailed steps in the [Git Safe Directory troubleshooting guide](/documentation/troubleshooting/git-safe-directory-windows).

**Quick fix:**

```bash
git config --global --add safe.directory "*"
```

Restart your terminal and IDE afterward. The guide also covers locking the setting down to specific FVM folders if you prefer a narrower scope.
