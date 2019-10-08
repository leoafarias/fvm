# `fvm`

![Coverage](coverage_badge.svg?sanitize=true) [![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php) [![Awesome Flutter](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

Flutter Version Management: A simple cli to manage Flutter SDK versions.

**Features:**

* Configure Flutter SDK version per project
* Ability to install and cache multiple Flutter SDK Versions
* Easily switch between Flutter channels & versions
* Per project Flutter SDK upgrade

## Version Management

This tool allows you to manage multiple; however, it caches these versions locally, so you don't have to wait for a full setup every time you want to switch versions.

Also, it allows you to grab versions by a specific release, i.e. 1.2.0. In case you have projects in different Flutter SDK versions and do not want to upgrade.

## Usage

To Setup:

```bash
$ pub global activate fvm
```

And then, for information on each command:

```bash
$ fvm help
```

### Install a SDK Version

FVM gives you the ability to install many Flutter **releases** or **channels**.

```bash
fvm install <version>
```

Version - use `master` to install the Master channel and `1.8.0` to install the release.

### Use a SDK Version

You can use different Flutter SDK versions per project. To do that you have to go into the root of the project and:

```bash
$ fvm use <version>
```

### Remove a SDK Version

Using the remove command will uninstall the SDK version locally. This will impact any projects that depend on that version of the SDK.

```bash
$ fvm remove <version>
```

### List Installed Versions

List all the versions that are installed on your machine.

```bash
$ fvm list
```

### Configure Your IDE
#### VSCode
Add the following to your settings.json

```json

"dart.flutterSdkPaths": [
    "fvm"
]
```

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
