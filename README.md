# fvm
Flutter Version Management: A simple cli to manage Flutter SDK versions.

##Installation

#### Binary installation

[Download](https://github.com/leoafarias/fvm/releases) a
compatible binary for your system. For convenience, place `fvm` in a
directory where you can access it from the command line. Usually this is
`/usr/local/bin`.

```bash
$ mv /path/to/fvm /usr/local/bin
```

#### Via Go

If you want, you can also get `fvm` via Go:

```bash
$ go get -u github.com/leoafarias/fvm
$ cd $GOPATH/src/github.com/leoafarias/fvm
$ go install .
```

## Usage

### Installing & Activating Releases & Channels
Use `fvm <version>` to install and activate a version of Flutter.

    $ fvm stable
    $ fvm beta
    
    $ fvm 1.2.1
    $ fvm 0.11.13
    

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

### Removing versions
Removes a specific version

    $ fvm remove <version>
    
Removes all Flutter versions, and channels

    $ fvm clean


