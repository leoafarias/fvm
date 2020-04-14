# `fvm`

![Coverage](https://raw.githubusercontent.com/leoafarias/fvm/master/coverage_badge.svg?sanitize=true) [![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php) [![Awesome Flutter](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

Flutter Version Management: A simple cli to manage Flutter SDK versions.

**Features:**

- Configure Flutter SDK version per project
- Ability to install and cache multiple Flutter SDK Versions
- Easily switch between Flutter channels & versions
- Per project Flutter SDK upgrade

## Version Management

This tool allows you to manage multiple channels and releases, and caches these versions locally, so you don't have to wait for a full setup every time you want to switch versions.

Also, it allows you to grab versions by a specific release, i.e. `v1.2.0` or `1.17.0-dev.3.1`. In case you have projects in different Flutter SDK versions and do not want to upgrade.

## Usage

To Install:

```bash
> pub global activate fvm
```

[Read dart.dev docs for more info](https://dart.dev/tools/pub/cmd/pub-global#running-a-script) on how to run global dart scripts.

And then, for information on each command:

```bash
> fvm help
```

### Install a SDK Version

FVM gives you the ability to install many Flutter **releases** or **channels**.

```bash
> fvm install <version>
```

Version - use `master` to install the Master channel and `v1.8.0` or `1.17.0-dev.3.1` to install the release.

### Use a SDK Version

You can use different Flutter SDK versions per project. To do that you have to go into the root of the project and:

```bash
> fvm use <version>
```

### Remove a SDK Version

Using the remove command will uninstall the SDK version locally. This will impact any projects that depend on that version of the SDK.

```bash
> fvm remove <version>
```

### List Installed Versions

List all the versions that are installed on your machine.

```bash
> fvm list
```

### Change FVM Cache Directory

There are some configurations that allows for added flexibility on FVM.

```bash
fvm config --cache-path <path-to-use>
```

### List Config Options

Returns list of all stored options in the config file.

```bash
fvm config --ls
```

### Running Flutter SDK

There are a couple of ways you can interact with the SDK setup in your project.

#### Proxy Commands

Flutter command within `fvm` proxies all calls to the CLI just changing the SDK to be the local one.

```bash
> fvm flutter run
```

This will run `flutter run` command using the local project SDK. If no FVM config is found in the project. FMV will recursively try for a version in a parent directory.

#### Call Local SDK Directly

FVM creates a symbolic link within your project called **fvm** which links to the installed version of the SDK.

```bash
> ./fvm run
```

This will run `flutter run` command using the local project SDK.

As an example calling `fvm flutter run` is the equivalent of calling `flutter run` using the local project SDK.

### Configure Your IDE

#### VSCode

Add the following to your settings.json

```json

"dart.flutterSdkPaths": [
    "fvm"
]
```

[Add your IDE instructions here](https://github.com/leoafarias/fvm/issues)

## Working with this repo

### Tests

```bash
pub run test
```

### Publishing package

Before pushing package to pub.dev. Run command to create version constant.

```bash
pub run build_runner build
```

### Update test coverage

To update test coverage run the following command.

```bash
pub run test_coverage
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/leoafarias"><img src="https://avatars1.githubusercontent.com/u/435833?v=4" width="50px;" alt=""/><br /><sub><b>Leo Farias</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=leoafarias" title="Documentation">📖</a> <a href="#ideas-leoafarias" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/leoafarias/fvm/commits?author=leoafarias" title="Code">💻</a> <a href="#example-leoafarias" title="Examples">💡</a> <a href="https://github.com/leoafarias/fvm/pulls?q=is%3Apr+reviewed-by%3Aleoafarias" title="Reviewed Pull Requests">👀</a> <a href="#maintenance-leoafarias" title="Maintenance">🚧</a> <a href="#infra-leoafarias" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
    <td align="center"><a href="https://github.com/ianko"><img src="https://avatars3.githubusercontent.com/u/723360?v=4" width="50px;" alt=""/><br /><sub><b>Ianko Leite</b></sub></a><br /><a href="#ideas-ianko" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://www.kikt.top"><img src="https://avatars0.githubusercontent.com/u/14145407?v=4" width="50px;" alt=""/><br /><sub><b>Caijinglong</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=CaiJingLong" title="Code">💻</a> <a href="#ideas-CaiJingLong" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://juejin.im/user/5bdc1a32518825170b101080"><img src="https://avatars1.githubusercontent.com/u/16477333?v=4" width="50px;" alt=""/><br /><sub><b>zmtzawqlp</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/issues?q=author%3Azmtzawqlp" title="Bug reports">🐛</a></td>
  </tr>
</table>

<!-- markdownlint-enable -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
