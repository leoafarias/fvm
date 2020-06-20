# Changelog

## 0.8.3

- Installation progress output
- Flutter setup on installation
- Ability to skip setup with`--skip-setup`

## 0.8.2

- Size optimization of SDK downloads
- Code clean-up

## 0.8.1

- Fixes `list` command when project has no config.

## 0.8.0

- Implemented `--global` flag to set a specific version globally.
- Changed project configuration to allow for versioning.
- Refactoring and project clean-up
- Better user experience
- Improved error messages

## 0.7.2

- Better compatibility with flutter commands.

## 0.7.1

- Updated version constant

## 0.7.0

- Added support for new Flutter 1.17.0+ [versioning scheme](https://groups.google.com/forum/#!msg/flutter-announce/b_EcYtyo8Q4/2QSfdp2aBwAJ) -
  The new versioning scheme includes changes to tag names and thus also version names for FVM. When reinstalling Flutter versions <1.17.0, the FVM install-path will change, potentially breaking projects that rely on the install-path.
  The install-path will change from `~/fvm/versions/1.15.17` to `~/fvm/versions/v1.15.17`. Make sure to change this in your IDE configuration.

## 0.6.7

- Added `version` command to see currently installed `fvm` version

## 0.6.6

- Better Flutter command compatibility
- Improved error logging and --verbose behavior
- Friendlier error messages

## 0.6.5

- Better Error handling and friendlier error message

## 0.6.4

- Project clean-up and tweaks for better pub analysis.

## 0.6.3

- Initial stable version rewritten in Dart.
