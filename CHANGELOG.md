## 3.0.0-beta.5

### Added

- Tighter VSCode integration, with configuration and settings management. FVM will now automatically configure VSCode to use the correct Flutter SDK version, triggering a termianl path update, so you can just use `flutter`, commands instead of `fvm flutter`
- Git Flutter repository mirroring for faster cloning of new versions.
- Added a check in .gitignore for the '.fvm' directory, and auto-adding it if necessary.
- Added verification if cached Flutter SDK has been upgraded, and provide options for corrective actions.
- Added a check for Flutter SDK constraints check for compatibility with current project.
- Improved FVM configuration management and settings.
- Ability to override FVM settings on a per project basis.
- Windows "unpriviledge" mode. If you you choose to run `fvm` in unpriviledge mode, it will not require admin rights to run, however local Flutter SDK project references will be absolute paths instead of relative links.

### Improvements

- Much improved DX with better error messages and logging, and more helpful information and how to proceed.
- Color output when using `fvm flutter` command proxy.
- Better SDK switching workflow per project. Handle more edge cases, by doing SDK comparisons.
- Better `fvm doctor` command. Now provides much better output and information about the project and environment.
- Better Dart SDK environment support, minimizes conflicts between multiple environment Dart SDKs.
- Improved `fvm releases` output.
- Improved `fvm list` output.
- Better error checking for `fvm global` command.
- FVM update check now runs only once a day.
- You can disable update check with the `--update-check` flag on `fvm config`

### Changed

- Command `fvm releases` now defaults to `stable` channel. Use `--all` flag to see all releases, or filter by channel.
- Removed "flavor" command in favor for `fvm use {flavor}`
- Removed "destroy" command in favor of `fvm remove --all`
- Config file is now `.fvmrc` instead of `.fvm/fvm_config.json`, and `.fvm` can be added to `.gitignore`, FVM will migrate it automatically.
- You can now use `fvm use {version} --env {flavor}` as an alias for `flavor`. Might be deprecated in the future since `env` has become a better description for environment specific settings than `flavor`.
- When installing or using a Flutter repo `commit hash`, hash needs ot be 10 digits. FVM will now validate it, and provide the correct hash if it can.

### Breaking Changes

- Default FVM config location is now `.fvmrc` instead of `.fvm/fvm_config.json`. FVM will migrate it automatically. However `.fvm` should be ignored, if you depend on `fvm_config.json` in your tools or CI, you should update your configuration.
- `fvm install` - Will not setup by default. Use `--setup` flag to setup Flutter SDK. Flag `--skip-setup` is removed.
- `fvm releases` - Defaults to `stable` releases. Use `--all` flag to see all releases, or filter by channel using `--channel {channel}`.
- `fvm flavor` - Removed in favor of `fvm use {flavor}`.
- `fvm use` - Will always setup by default. Use `--skip-setup` flag to skip setup.
- Environment variables `FVM_HOME` is now `FVM_CACHE_PATH`.
- Environment variables `FVM_GIT_CACHE` is now `FVM_FLUTTER_URL`.

## 2.4.1 - 2022-07-06

- Filter out Mac releases based on architecture.

## 2.4.0 - 2022-07-05

- Upgraded minimum Dart version to 2.17.0 for better Flutter 3.0 compatibility.

## 2.3.1 - 2022-04-07

- Updated Flutter releases endpoint.

## 2.3.0 - 2022-04-06

- Implemented `fvm exec` command. Execute terminal commands with the configured Flutter/Dart SDK version in the environment.
- `fvm use` command will install configured version by default if no version is provided.

## 2.2.6 - 2021-12-14

- Fixed an issue with routing to older Dart SDK directory path (before 1.17.5).

## 2.2.5 - 2021-12-09

- Clean `dart` command output `stdout` [Issue #361](https://github.com/leoafarias/fvm/issues/361).
- Better experience when running `dart pub cache repair` [Issue #352](https://github.com/leoafarias/fvm/issues/352).
- Dart proxy points to the correct path when version is older than 1.20.0 [Issue #348](https://github.com/leoafarias/fvm/issues/348).
- Flavors sequence of command causes `null` check exception [Issue #358](https://github.com/leoafarias/fvm/issues/358).

## 2.2.4 - 2021-11-09

- Ensures SDK is setup when running `use` command.

## 2.2.3 - 2021-08-31

- Fix archive URL from release info.

## 2.2.2 - 2021-06-18

- Small fix when checking for upgrade.

## 2.2.1 - 2021-06-18

- Fixed an edge case when running `flutter` command with `--no-version-check` flag.

## 2.2.0 - 2021-06-17

- Resolves channel unknown when pulling release version.
- Allows for release install of different channels [Read more](https://fvm.app/docs/advanced/release_multiple_channels).

## 2.1.1 - 2021-06-16

- Removed Flutter version validation check.
- Offline support.

## 2.1.0 - 2021-06-14

- Removed Windows permission check.

## 2.0.7 - 2021-06-14

- Updated Flutter releases URL.

## 2.0.6 - 2021-06-02

- Added a fallback if Flutter Release API is down.

## 2.0.5 - 2021-05-19

- Fixed concurrent Flutter commands execution on monorepos [Issue #296](https://github.com/leoafarias/fvm/issues/296).
- Added `cli_notify` to check for new version updates.

## 2.0.4 - 2021-05-06

- FVM only outputs information about version running when using `--verbose` flag [\#288](https://github.com/leoafarias/fvm/issues/288).

## 2.0.3 - 2021-05-04

- Fixed monorepo compatibility [Issue #285](https://github.com/leoafarias/fvm/issues/285).

## 2.0.2 - 2021-05-04

- Fixed a regression when running `fvm install` command.

## 2.0.1 - 2021-05-01

- Fix issue when retrieving settings [Issue #281](https://github.com/leoafarias/fvm/issues/281).

## 2.0.0 - 2021-05-01

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

## 1.3.8 - 2021-03-26

- Fixed an issue on FVM install [Issue #242](https://github.com/leoafarias/fvm/issues/242).
- Fixed an Auto linking issue [Issue #207](https://github.com/leoafarias/fvm/issues/207).

## 1.3.7 - 2020-12-18

- Fixed an issue for unwanted delay appearing after running `fvm use` command [\#195](https://github.com/leoafarias/fvm/issues/195).

## 1.3.6 - 2020-10-29

- Improvement: Added `PATH` env on Flutter processs for better third party tooling support.
- Fix: Updated Grinder dependencies.
- Fix: Better ancestor lookup logic for monorepo setups. [Issue #180](https://github.com/leoafarias/fvm/issues/180).

## 1.3.5+1 - 2020-10-29

- Added symlink on install behavior without version.
- Clean-up.

## 1.3.4 - 2020-10-15

- Better support for CI and custom workflows using `fvm flutter ...` commands.

## 1.3.3 - 2020-10-14

- Fixed an error when setting up on some platforms and tools [Issue #160](https://github.com/leoafarias/fvm/issues/160).

## 1.3.2 - 2020-10-13

- Better logging for Flutter setup.

## 1.3.1 - 2020-10-11

- Fix issue when running `install` command with pinned version [Issue #161](https://github.com/leoafarias/fvm/issues/161).

## 1.3.0 - 2020-07-16

- Bug fixes and improvements.
- Implemented ability to change `cachePath` on settings [Issue #101](https://github.com/leoafarias/fvm/issues/101).
- Improved UX with `flutter run` command [Issue #124](https://github.com/leoafarias/fvm/issues/124).
- Added a notice on Windows to run in developer or administrator mode.
- Ability to set Flutter Git Repo URL (Advanced).

## 1.2.3 - 2020-08-22

- Clone setting changes. Unexpected behavior when installing master in some cases.

## 1.2.2 - 2020-08-19

- Updated process\_run dependency [(Issue #113)](https://github.com/fluttertools/fvm/pull/113).

## 1.2.0 - 2020-08-16

- `Use` command now shows the installed version if no 'version' is passed.
- Improved exception message handling.

## 1.1.9 - 2020-08-15

- Improvements on `flutter` channels parsing.

## 1.1.8 - 2020-08-14

- Fix for shared releases between channels.

## 1.1.7 - 2020-08-12

- Changed version on builder.

## 1.1.6 - 2020-08-12

- Better support for Windows.

## 1.1.5 - 2020-07-27

- Added a message with notice and fix if Flutter releases URL is blocked in your country.

## 1.1.4 - 2020-07-27

- Nested FVM config look up; to be used on monorepo projects or nested directories.
- Added a link to changelog on upgrade message.

## 1.1.3 - 2020-07-17

- Removed Flutter project guard from `flutter` proxy command.

## 1.1.2 - 2020-07-17

- Added upgrade message if not running the latest `fvm` version.

## 1.1.1 - 2020-07-17

- Static analysis and Dart convention notes added to README.md.

## 1.1.0 - 2020-07-16

- Implemented `--force` flag on `use` command to bypass guards if needed.
- Set where `fvm` caches versions using `FVM_HOME` environment variable.
- Deprecated `--cache-path` flag in favor of `FVM_HOME`.

## 1.0.4 - 2020-07-02

- Indicates global version on `list` command.

## 1.0.3 - 2020-07-02

- Fixed an issue with `stdin` on [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli) commands.

## 1.0.2 - 2020-06-23

- Indicates channels on `fvm releases` command.

## 1.0.1 - 2020-06-22

- Suppress verbose message for install progress.

## 1.0.0 - 2020-06-22

- List Flutter Releases functionality.
- Bug fixes and optimizations.
- Project refactoring.

## 0.8.3 - 2020-06-20

- Installation progress output.
- Flutter setup on installation.
- Ability to skip setup with `--skip-setup` flag.

## 0.8.2 - 2020-06-19

- Size optimization of Flutter SDK downloads.
- Code clean-up.

## 0.8.1 - 2020-06-19

- Fixed `list` command when project has no config.

## 0.8.0 - 2020-06-18

- Implemented `--global` flag to set a specific version globally.
- Changed project configuration to allow for versioning.
- Refactoring and project clean-up.
- Better user experience.
- Improved error messages.

## 0.7.2 - 2020-06-18

- Better compatibility with [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli) commands.

## 0.7.1 - 2020-06-18

- Updated `version` constant.

## 0.7.0 - 2020-04-14

- Added support for new Flutter 1.17.0+ [versioning scheme](https://groups.google.com/forum/#!msg/flutter-announce/b_EcYtyo8Q4/2QSfdp2aBwAJ) -
The new versioning scheme includes changes to tag names and thus also version names for FVM. When reinstalling Flutter versions <1.17.0, the FVM `install-path` will change, potentially breaking projects that rely on the `install-path`.
The `install-path` will change from `~/fvm/versions/1.15.17` to `~/fvm/versions/v1.15.17` (notice the letter `v` in the new version directory name). Make sure to change this in your IDE configuration.

## 0.6.7 - 2019-12-26

- Added `version` command to see currently installed `fvm` version.

## 0.6.6 - 2019-11-08

- Better [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli) commands compatibility.
- Improved error logging and `--verbose` flag behavior.
- Friendlier error messages.

## 0.6.5 - 2019-11-08

- Better Error handling and friendlier error messages.

## 0.6.4 - 2019-11-08

- Project clean-up and tweaks for better `pub` analysis.

## 0.6.3 - 2019-11-07

- Initial stable version rewritten in Dart.
