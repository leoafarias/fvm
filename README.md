![](https://raw.githubusercontent.com/leoafarias/fvm/master/assets/logo.png)
___
Flutter Version Management: A simple cli to manage Flutter SDK versions.


[![Go Report Card](https://goreportcard.com/badge/github.com/leoafarias/fvm)](https://goreportcard.com/report/github.com/leoafarias/go-fvm)
[![Build Status](https://travis-ci.org/leoafarias/fvm.svg?branch=master)](https://travis-ci.org/leoafarias/fvm)
[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)

![](https://raw.githubusercontent.com/leoafarias/fvm/master/assets/terminal.gif)
## Why not use Flutter Channels?
If all you want is to use the latest stable version or a specific channel once in a while, you should be using [Flutter Channels](https://github.com/flutter/flutter/wiki/Flutter-build-release-channels).

This tool allows you similar functionality to Channels; however it caches those versions locally, so you don't have to wait for a full setup every time you want to switch versions.

Also, it allows you to grab versions by a specific tag, i.e. 1.2.0. In case you have projects in different Flutter SDK versions and do not want to upgrade.


#### Binary installation

[Download](https://github.com/leoafarias/fvm/releases) a
compatible binary for your system. For convenience, place `fvm` in a
directory where you can access it from the command line. Usually this is
`/usr/local/bin`.

For more detailed instructions check out [Installation](https://go.equinox.io/github.com/leoafarias/fvm)

#### Via Go

If you want, you can also get `fvm` via Go:

```bash
$ go get -u github.com/leoafarias/fvm
$ cd $GOPATH/src/github.com/leoafarias/fvm
$ go install .
```

## Usage

### Installing and Activating Releases/Channels
Use `fvm <version>` to install and activate a version of Flutter.

    $ fvm 1.2.1
    $ fvm 0.11.13

    $ fvm stable
    $ fvm beta
    
    

If `<version>` has already been installed, `fvm` will activate it from cache without having to download and set up again.

Lists all currently installed versions

    $ fvm
            v1.2.1
        >   v0.11.13
            master
            stable


Use `fvm <channel>` to install and activate a particular Flutter channel.

User or install the latest `stable` release

    $ fvm stable

User or install the latest `beta` release

    $ fvm beta

User or install the latest fully-tested build

    $ fvm dev

User or intall the latest cutting edge build

    $ fvm master

### Releases
See all available releases for download

    $ fvm releases

### Removing versions
Removes a specific version

    $ fvm remove <version>
    
Removes all Flutter versions except the active one

    $ fvm shake


## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details