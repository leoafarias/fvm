# fvm
Flutter Version Management: A simple cli to manage Flutter SDK versions.

## Installation

## Usage

### Installing & Activating Releases & Channels
Use `fvm <version>` to install and activate a release of Flutter.

    $ fvm 1.2.1
    $ fvm 0.11.13

If `<version>` has already been installed, `fvm` will activate it from cache without having to download and set up again.

Lists all currently installed versions

    $ fvm list
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
    
Removes all versions except the current activated one

    $ fvm shake


