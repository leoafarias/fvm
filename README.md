# `fvm`

[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)
[![Awesome Flutter](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

Flutter Version Management: A simple cli to manage Flutter SDK versions.

Features:

* Configure Flutter SDK version per project
* Ability to install and cache multiple Flutter SDK Versions
* Easily switch between Flutter channels & versions
* Per project Flutter SDK upgrade

## Project Specific Channels or Versions

If all you want is to use the latest stable version or a specific channel for all your projects, you should be using [Flutter Channels](https://github.com/flutter/flutter/wiki/Flutter-build-release-channels).

This tool allows you similar functionality to Channels; however it caches those versions locally, so you don't have to wait for a full setup every time you want to switch versions.

Also, it allows you to grab versions by a specific tag, i.e. 1.2.0. In case you have projects in different Flutter SDK versions and do not want to upgrade.

## Usage

To install:

```bash
$ pub global activate fvm
```

And then, for information on each command:

```bash
$ fvm help
```

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
