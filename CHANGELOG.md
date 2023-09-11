# Changelog

## Unreleased

- Implemented .gitignore notice to setup `fvm`
- Configure vscode automatically
- Check .gitignore for cached version
- Cache clean up, and corrective action in case of corrupted cache or upgraded SDK
- Flutter repo git reference for much faster clone of new versions.
- Removed --skip-setup on `use` command. If you need to install without setting up, you should use `install`. You can force SDK setup on install by using -s or --setup

## 2.4.1

- Filter out Mac releases based on architecture.

## 2.4.0

- Upgraded minimum Dart version to 2.17.0 for better Flutter 3.0 compatibility.

## 2.3.1

- Updated Flutter releases endpoint.

## 2.3.0

- Implemented `fvm exec` command. Execute terminal commands with the configured Flutter/Dart SDK version in the environment.
- `fvm use` command will install configured version by default if no version is provided.

## 2.2.6

- Fixed an issue with routing to older Dart SDK directory path (before 1.17.5).

## 2.2.5

- Clean `dart` command output `stdout` [Issue #361](https://github.com/leoafarias/fvm/issues/361).
- Better experience when running `dart pub cache repair` [Issue #352](https://github.com/leoafarias/fvm/issues/352).
- Dart proxy points to the correct path when version is older than 1.20.0 [Issue #348](https://github.com/leoafarias/fvm/issues/348).
- Flavors sequence of command causes `null` check exception [Issue #358](https://github.com/leoafarias/fvm/issues/358).

## 2.2.4

- Ensures SDK is setup when running `use` command.

## 2.2.3

- Fix archive URL from release info.

## 2.2.2

- Small fix when checking for upgrade.

## 2.2.1

- Fixed an edge case when running `flutter` command with `--no-version-check` flag.

## 2.2.0

- Resolves channel unknown when pulling release version.
- Allows for release install of different channels [Read more](https://fvm.app/docs/advanced/release_multiple_channels).

## 2.1.1

- Removed Flutter version validation check.
- Offline support.

## 2.1.0

- Removed Windows permission check.

## 2.0.7

- Updated Flutter releases URL.

## 2.0.6

- Added a fallback if Flutter Release API is down.

## 2.0.5

- Fixed concurrent Flutter commands execution on monorepos [Issue #296](https://github.com/leoafarias/fvm/issues/296).
- Added `cli_notify` to check for new version updates.

## 2.0.4

- FVM only outputs information about version running when using `--verbose` flag [#288](https://github.com/leoafarias/fvm/issues/288).

## 2.0.3

- Fixed monorepo compatibility [Issue #285](https://github.com/leoafarias/fvm/issues/285).

## 2.0.2

- Fixed a regression when running `fvm install` command.

## 2.0.1

- Fix issue when retrieving settings [Issue #281](https://github.com/leoafarias/fvm/issues/281).

## 2.0.0

- Feature: Environments - Set Flutter SDK versions per project environment.
- Feature: Doctor - Easily view the Flutter SDK version configuration for the project and the configuration state.
- Feature: Spawn - Easily proxy Flutter CLI commands through any cached version.
- Feature: Commits - Ability to install/use commits as the pinned Flutter SDK version.
- Feature: Custom versions - Manage custom Flutter SDK versions by adding `custom_` in front of the version.
- Improvements: null-safety.
- Improvements: Global - Create own command to set global versions. Deprecated `--global` flag.
- Improvements: Flutter command proxy now defaults to FVM global configured version before looking for one configured on `PATH`.
- Improvements: Better error messaging, notifications and logging.
- Improvements: Many quality of life (QoL) improvements.

## 1.3.8

- Fixed an issue on FVM install [Issue #242](https://github.com/leoafarias/fvm/issues/242).
- Fixed an Auto linking issue [Issue #207](https://github.com/leoafarias/fvm/issues/207).

## 1.3.7

- Fixed an issue for unwanted delay appearing after running `fvm use` command [#195](https://github.com/leoafarias/fvm/issues/195).

## 1.3.6

- Improvement: Added `PATH` env on Flutter processs for better third party tooling support.
- Fix: Updated Grinder dependencies.
- Fix: Better ancestor lookup logic for monorepo setups. [Issue #180](https://github.com/leoafarias/fvm/issues/180).

## 1.3.5+1

- Added symlink on install behavior without version.
- Clean-up.

## 1.3.4

- Better support for CI and custom workflows using `fvm flutter ...` commands.

## 1.3.3

- Fixed an error when setting up on some platforms and tools [Issue #160](https://github.com/leoafarias/fvm/issues/160).

## 1.3.2

- Better logging for Flutter setup.

## 1.3.1

- Fix issue when running `install` command with pinned version [Issue #161](https://github.com/leoafarias/fvm/issues/161).

## 1.3.0

- Bug fixes and improvements.
- Implemented ability to change `cachePath` on settings [Issue #101](https://github.com/leoafarias/fvm/issues/101).
- Improved UX with `flutter run` command [Issue #124](https://github.com/leoafarias/fvm/issues/124).
- Added a notice on Windows to run in developer or administrator mode.
- Ability to set Flutter Git Repo URL (Advanced).

## 1.2.3

- Clone setting changes. Unexpected behavior when installing master in some cases.

## 1.2.2

- Updated process_run dependency [(Issue #113)](https://github.com/fluttertools/fvm/pull/113).

## 1.2.0

- `Use` command now shows the installed version if no 'version' is passed.
- Improved exception message handling.

## 1.1.9

- Improvements on `flutter` channels parsing.

## 1.1.8

- Fix for shared releases between channels.

## 1.1.7

- Changed version on builder.

## 1.1.6

- Better support for Windows.

## 1.1.5

- Added a message with notice and fix if Flutter releases URL is blocked in your country.

## 1.1.4

- Nested FVM config look up; to be used on monorepo projects or nested directories.
- Added a link to changelog on upgrade message.

## 1.1.3

- Removed Flutter project guard from `flutter` proxy command.

## 1.1.2

- Added upgrade message if not running the latest `fvm` version.

## 1.1.1

- Static analysis and Dart convention notes added to README.md.

## 1.1.0

- Implemented `--force` flag on `use` command to bypass guards if needed.
- Set where `fvm` caches versions using `FVM_HOME` environment variable.
- Deprecated `--cache-path` flag in favor of `FVM_HOME`.

## 1.0.4

- Indicates global version on `list` command.

## 1.0.3

- Fixed an issue with `stdin` on [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli) commands.

## 1.0.2

- Indicates channels on `fvm releases` command.

## 1.0.1

- Suppress verbose message for install progress.

## 1.0.0

- List Flutter Releases functionality.
- Bug fixes and optimizations.
- Project refactoring.

## 0.8.3

- Installation progress output.
- Flutter setup on installation.
- Ability to skip setup with `--skip-setup` flag.

## 0.8.2

- Size optimization of Flutter SDK downloads.
- Code clean-up.

## 0.8.1

- Fixed `list` command when project has no config.

## 0.8.0

- Implemented `--global` flag to set a specific version globally.
- Changed project configuration to allow for versioning.
- Refactoring and project clean-up.
- Better user experience.
- Improved error messages.

## 0.7.2

- Better compatibility with [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli) commands.

## 0.7.1

- Updated `version` constant.

## 0.7.0

- Added support for new Flutter 1.17.0+ [versioning scheme](https://groups.google.com/forum/#!msg/flutter-announce/b_EcYtyo8Q4/2QSfdp2aBwAJ) -
  The new versioning scheme includes changes to tag names and thus also version names for FVM. When reinstalling Flutter versions <1.17.0, the FVM `install-path` will change, potentially breaking projects that rely on the `install-path`.
  The `install-path` will change from `~/fvm/versions/1.15.17` to `~/fvm/versions/v1.15.17` (notice the letter `v` in the new version directory name). Make sure to change this in your IDE configuration.

## 0.6.7

- Added `version` command to see currently installed `fvm` version.

## 0.6.6

- Better [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli) commands compatibility.
- Improved error logging and `--verbose` flag behavior.
- Friendlier error messages.

## 0.6.5

- Better Error handling and friendlier error messages.

## 0.6.4

- Project clean-up and tweaks for better `pub` analysis.

## 0.6.3

- Initial stable version rewritten in Dart.
